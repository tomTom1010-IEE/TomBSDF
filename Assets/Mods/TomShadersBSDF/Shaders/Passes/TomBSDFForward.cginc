#ifndef TOM_BSDF_FORWARD_INCLUDED
#define TOM_BSDF_FORWARD_INCLUDED
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "UnityStandardUtils.cginc"
#include "../Material/TomBSDFSurface.cginc"
#if defined(TOM_BSDF_PARALLAX)
    #include "../Core/TomBSDFParallax.cginc"
#endif
#include "../Platform/Unity2019/TomBSDFLightingAdapter.cginc"
#if defined(TOM_BSDF_GLINTS)
    #include "../Lighting/TomBSDFGlintsLighting.cginc"
#endif
#if defined(TOM_BSDF_ALPHA)
    #include "../Platform/Unity2019/TomBSDFShadowReceiverAdapter.cginc"
#endif
#if defined(UNITY_PASS_FORWARDBASE) && (defined(TOM_BSDF_AREA_REALTIME) || defined(TOM_BSDF_AREA_REFERENCE))
    #define TOM_BSDF_COMPILE_AREA 1
    #include "../Lighting/TomBSDFRectArea.cginc"
#endif

struct TomVertexInput
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
};

struct TomVertexOutput
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 position : TEXCOORD1;
    float3 normal : TEXCOORD2;
    float4 tangent : TEXCOORD3;
    UNITY_SHADOW_COORDS(4)
    UNITY_FOG_COORDS(5)
    float fallbackLights : TEXCOORD6;
};

TomVertexOutput TomBSDFVertex(TomVertexInput v)
{
    TomVertexOutput o;
    UNITY_INITIALIZE_OUTPUT(TomVertexOutput, o);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.uv;
    o.position = mul(unity_ObjectToWorld, v.vertex).xyz;
    o.normal = mul(v.normal, (float3x3)unity_WorldToObject);
    o.tangent = float4(mul((float3x3)unity_ObjectToWorld, v.tangent.xyz), v.tangent.w * unity_WorldTransformParams.w);
    // Unity 2019's fwdbase VERTEXLIGHT_ON is a vertex-stage variant. Carry its
    // decision into the fragment stage rather than reading stale four-light data.
    #if defined(VERTEXLIGHT_ON) && defined(UNITY_PASS_FORWARDBASE)
        o.fallbackLights = 1.0;
    #else
        o.fallbackLights = 0.0;
    #endif
    UNITY_TRANSFER_SHADOW(o, float2(0,0));
    #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
        // Raw eye depth works for both perspective and orthographic cameras.
        o.fogCoord.x = -mul(UNITY_MATRIX_V, float4(o.position, 1.0)).z;
    #endif
    return o;
}

float4 TomBSDFFragment(TomVertexOutput i, float facing : VFACE) : SV_Target
{
    TomSurfaceCoordinates coordinates = TomUnshiftedCoordinates(i.uv);
    #if defined(TOM_BSDF_PARALLAX) || defined(TOM_BSDF_GLINTS)
        coordinates.dx = ddx(i.uv);
        coordinates.dy = ddy(i.uv);
    #endif
    #if defined(TOM_BSDF_PARALLAX)
        float3 positionDx = ddx(i.position), positionDy = ddy(i.position);
    #endif
    float coverage = TomCoverage(i.uv);
    TomClipCoverage(coverage);
    #if defined(TOM_BSDF_PARALLAX)
        float3 parallaxView = TomSafeNormalize(lerp(UnityWorldSpaceViewDir(i.position), UNITY_MATRIX_V[2].xyz, unity_OrthoParams.w));
        TomHeightContext heightContext;
        coordinates = TomParallaxCoordinates(coordinates, i.position, i.normal, parallaxView, positionDx, positionDy, heightContext);
        // Derivatives are evaluated after reconverging the bounded trace, never
        // within its divergent loop. Off/zero retain the original implicit samples.
        float2 shiftedDx = ddx(coordinates.uv), shiftedDy = ddy(coordinates.uv);
        if (coordinates.explicitGrad > 0.5)
        {
            coordinates.dx = TomParallaxFootprint(shiftedDx, coordinates.dx);
            coordinates.dy = TomParallaxFootprint(shiftedDy, coordinates.dy);
        }
    #endif
    float marker = tex2Dlod(_TomBSDFEnergyLUT, float4(0.5, 0.5, 0, 0)).a;
    if (abs(marker - 0.5) > 0.01)
    {
        #if defined(UNITY_PASS_FORWARDBASE)
            return TomCoverageOutput(float3(1, 0, 1), coverage);
        #else
            return 0.0;
        #endif
    }
    TomBSDFMaterial m = TomReadMaterial(coordinates);
    TomBSDFGeometry g = TomReadGeometry(i.position, i.normal, i.tangent, coordinates, facing > 0 ? 1.0 : -1.0);
    TomBSDFGeometry normalFrame = g;
    if (_Anisotropy > 0.0)
    {
        float anisotropicMarker = _TomBSDFAnisoEnergyLUT.SampleLevel(tom_aniso_linear_clamp_sampler, float3(0.5, 0.5, 0.5), 0).a;
        if (abs(anisotropicMarker - 0.625) > 0.01)
        {
            #if defined(UNITY_PASS_FORWARDBASE)
                return TomCoverageOutput(float3(1, 0, 1), coverage);
            #else
                return 0.0;
            #endif
        }
        TomRotateAnisotropicFrame(g, m.anisotropyRotation);
    }
    // Apply once before all D/G/DFG/IBL evaluations, identically in Base and Add.
    TomBSDFMaterial intrinsic = m;
    #if defined(TOM_BSDF_GLINTS)
        TomGlintFootprint glints = TomReadGlints(coordinates,intrinsic);
    #endif
    float3 normalDx = ddx(g.normal), normalDy = ddy(g.normal);
    float rotationDx = dot(g.bitangent, ddx(g.tangent));
    float rotationDy = dot(g.bitangent, ddy(g.tangent));
    if (_SpecularAAStrength > 0.0)
    {
        if (m.anisotropy > 0.0)
            TomFilterAnisotropicRoughness(m, dot(normalDx, normalDx) + dot(normalDy, normalDy),
                rotationDx * rotationDx + rotationDy * rotationDy, _SpecularAAStrength, _SpecularAAVariance, _SpecularAAThreshold);
        else
            m.roughness = TomFilterSpecularRoughness(m.roughness, normalDx, normalDy,
                _SpecularAAStrength, _SpecularAAVariance, _SpecularAAThreshold);
    }
    TomBSDFEnergy ev = TomReadDirectionalEnergy(m, g, g.view);
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.position);
    #if defined(TOM_BSDF_ALPHA)
        attenuation = TomAlphaNativeLightAttenuation(i.position, attenuation);
    #endif
    #if defined(TOM_BSDF_PARALLAX) || defined(TOM_BSDF_GLINTS)
        TomBSDFLight currentLight = TomUnityCurrentLight(i.position, attenuation);
    #endif
    #if defined(TOM_BSDF_PARALLAX)
        currentLight = TomUnityHeightVisibility(currentLight, heightContext, _WorldSpaceLightPos0);
    #endif
    float3 color;
    if (_CoatWeight > 0.0)
    {
        if(_ThinFilmWeight>0.0 && _ThinFilmQuality<0.5)
        {
            uint width,height,depth;_TomBSDFFilmEnergyLUT.GetDimensions(width,height,depth);
            if(width!=65 || height!=17 || depth!=1224)
            {
                #if defined(UNITY_PASS_FORWARDBASE)
                    return TomCoverageOutput(float3(1,0,1), coverage);
                #else
                    return 0.0;
                #endif
            }
        }
        TomBSDFLayers layers = TomReadLayers(coordinates, intrinsic, g, normalFrame,
            dot(normalDx, normalDx) + dot(normalDy, normalDy), rotationDx * rotationDx + rotationDy * rotationDy);
        #if defined(TOM_BSDF_GLINTS)
            color = TomEvaluateGlintLayerLight(m,g,ev,layers,currentLight,glints);
        #elif defined(TOM_BSDF_PARALLAX)
            color = TomEvaluateLayerLight(m, g, ev, layers, currentLight);
        #else
            color = TomEvaluateLayerLight(m, g, ev, layers, TomUnityCurrentLight(i.position, attenuation));
        #endif
        #if defined(UNITY_PASS_FORWARDBASE)
            #if defined(TOM_BSDF_GLINTS)
            color += TomUnityGlintFallbackLights(m,g,ev,layers,true,i.fallbackLights,glints
                #if defined(TOM_BSDF_PARALLAX)
                    ,heightContext
                #endif
            );
            #else
            color += TomUnityLayerFallbackLights(m, g, ev, layers, i.fallbackLights
                #if defined(TOM_BSDF_PARALLAX)
                    , heightContext
                #endif
            );
            #endif
            color += TomUnityLayerIndirect(m, g, ev, layers);
            #if defined(TOM_BSDF_COMPILE_AREA)
                color += TomEvaluateRectLights(m, g, ev, layers, layers.weight > 0.0);
            #endif
        #endif
    }
    else
    {
        #if defined(TOM_BSDF_GLINTS)
            color = TomEvaluateGlintLight(m,g,ev,currentLight,glints);
        #elif defined(TOM_BSDF_PARALLAX)
            color = TomEvaluateLight(m, g, ev, currentLight);
        #else
            color = TomEvaluateLight(m, g, ev, TomUnityCurrentLight(i.position, attenuation));
        #endif
        #if defined(UNITY_PASS_FORWARDBASE)
            #if defined(TOM_BSDF_GLINTS)
            TomBSDFLayers uncoated = (TomBSDFLayers)0;
            uncoated.ior=1.0;uncoated.film.incidentIOR=1.0;uncoated.film.filmIOR=1.0;uncoated.film.dielectricIOR=1.0;
            color += TomUnityGlintFallbackLights(m,g,ev,uncoated,false,i.fallbackLights,glints
                #if defined(TOM_BSDF_PARALLAX)
                    ,heightContext
                #endif
            );
            #else
            color += TomUnityFallbackLights(m, g, ev, i.fallbackLights
                #if defined(TOM_BSDF_PARALLAX)
                    , heightContext
                #endif
            );
            #endif
            color += TomUnityIndirect(m, g, ev) + m.emission;
            #if defined(TOM_BSDF_COMPILE_AREA)
            TomBSDFLayers noLayers = (TomBSDFLayers)0;
            // FXC analyzes inlined inactive branches too; zero IOR is not a
            // valid optical domain even though the layer weight remains zero.
            noLayers.ior = 1.0;
            noLayers.film.incidentIOR = 1.0;
            noLayers.film.filmIOR = 1.0;
            noLayers.film.dielectricIOR = 1.0;
            color += TomEvaluateRectLights(m, g, ev, noLayers, false);
            #endif
        #endif
    }
    #if defined(UNITY_PASS_FORWARDBASE)
        if (_DebugView > 0.5 && _DebugView < 1.5) color = m.baseColor;
        else if (_DebugView < 2.5 && _DebugView > 1.5) color = g.normal * 0.5 + 0.5;
        else if (_DebugView < 3.5 && _DebugView > 2.5) color = float3(m.occlusion, m.roughness, m.metalness);
        else if (_DebugView < 4.5 && _DebugView > 3.5) color = coverage.xxx;
        else if (_DebugView > 4.5 && _DebugView < 5.5) color = attenuation.xxx;
        else if (_DebugView > 5.5 && _DebugView < 6.5)
        {
            color = i.fallbackLights.xxx;
        }
        else if (_DebugView > 6.5 && _DebugView < 7.5) color = TomUnityDiffuseEnvironment(g);
        else if (_DebugView > 7.5 && _DebugView < 8.5) color = TomUnityProbeEnvironment(m, g);
        else if (_DebugView > 8.5 && _DebugView < 9.5) color = TomIndirectSpecularVisibility(m, g).xxx;
        else if (_DebugView > 9.5 && _DebugView < 10.5) color = m.roughness.xxx;
        else if (_DebugView > 10.5 && _DebugView < 11.5) color = TomCustomSH(g).aaa;
        else if (_DebugView > 11.5 && _DebugView < 12.5) color = g.tangent * 0.5 + 0.5;
        else if (_DebugView > 12.5 && _DebugView < 13.5) color = float3(TomAnisotropicAxes(m.roughness, m.anisotropy), m.anisotropy);
        else if (_DebugView > 13.5) color = float3(ev.dfg, ev.missingAverage);
    #else
        if (_DebugView > 0.5) color = 0.0;
    #endif
    float4 result = float4(TomSceneOutput(color), 1.0);
    #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
        float3 fogColor = 0.0;
        #if defined(UNITY_PASS_FORWARDBASE)
            fogColor = unity_FogColor.rgb;
        #endif
        UNITY_CALC_FOG_FACTOR_RAW(i.fogCoord.x);
        result.rgb = TomSceneFog(result.rgb, fogColor, unityFogFactor);
    #endif
    #if defined(TOM_BSDF_ALPHA)
        // Fog, reflections, all layers and emission share geometric coverage.
        // Add uses One/One and writes no alpha, so background is attenuated once.
        result = TomCoverageOutput(result.rgb, coverage);
    #endif
    #if defined(UNITY_PASS_FORWARDADD)
        result.a = 0.0;
    #endif
    return result;
}
#endif
