#ifndef TOM_BSDF_GLASS_PASS_INCLUDED
#define TOM_BSDF_GLASS_PASS_INCLUDED
#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "UnityStandardUtils.cginc"
#include "../Material/TomBSDFGlassSurface.cginc"
#include "../Platform/Unity2019/TomBSDFGlassRefraction.cginc"
#if !defined(TOM_GLASS_TRANSMISSION_PASS)
    #include "../Platform/Unity2019/TomBSDFLightingAdapter.cginc"
    #include "../Platform/Unity2019/TomBSDFShadowReceiverAdapter.cginc"
    #if defined(UNITY_PASS_FORWARDBASE) && (defined(TOM_BSDF_AREA_REALTIME) || defined(TOM_BSDF_AREA_REFERENCE))
        #define TOM_BSDF_COMPILE_AREA 1
        #include "../Lighting/TomBSDFRectArea.cginc"
    #endif
#endif

struct TomGlassVertexInput
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
};
struct TomGlassVaryings
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
TomGlassVaryings TomGlassVertex(TomGlassVertexInput v)
{
    TomGlassVaryings o;
    UNITY_INITIALIZE_OUTPUT(TomGlassVaryings, o);
    o.pos = UnityObjectToClipPos(v.vertex); o.uv = v.uv;
    o.position = mul(unity_ObjectToWorld, v.vertex).xyz;
    o.normal = mul(v.normal, (float3x3)unity_WorldToObject);
    o.tangent = float4(mul((float3x3)unity_ObjectToWorld, v.tangent.xyz), v.tangent.w * unity_WorldTransformParams.w);
    #if defined(VERTEXLIGHT_ON) && defined(UNITY_PASS_FORWARDBASE)
        o.fallbackLights = 1.0;
    #endif
    UNITY_TRANSFER_SHADOW(o, float2(0,0));
    #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
        o.fogCoord.x = -mul(UNITY_MATRIX_V, float4(o.position, 1.0)).z;
    #endif
    return o;
}

float4 TomGlassFragment(TomGlassVaryings i, float facing : VFACE) : SV_Target
{
    TomGlassSurface s = TomReadGlassSurface(i.uv, i.position, i.normal, i.tangent, facing);
    #if defined(TOM_GLASS_TRANSMISSION_PASS)
        if (_DebugView > 0.5) return float4((1.0 - s.coverage).xxx, s.coverage);
        TomGlassScreenHit hit = TomGlassFindBackground(s);
        float3 multiplier = 1.0 - s.coverage + s.coverage * s.transport.transmission * (1.0 - hit.weight);
        return float4(multiplier, s.coverage);
    #else
        float marker = tex2Dlod(_TomBSDFEnergyLUT, float4(0.5, 0.5, 0, 0)).a;
        if (abs(marker - 0.5) > 0.01) return float4(1,0,1,0);
        UNITY_LIGHT_ATTENUATION(attenuation, i, i.position);
        attenuation = TomAlphaNativeLightAttenuation(i.position, attenuation);
        float3 reflection = TomEvaluateLight(s.material, s.geometry, s.energy, TomUnityCurrentLight(i.position, attenuation));
        float3 color;
        #if defined(UNITY_PASS_FORWARDBASE)
            reflection += TomUnityFallbackLights(s.material, s.geometry, s.energy, i.fallbackLights)
                + TomUnityIndirect(s.material, s.geometry, s.energy);
            #if defined(TOM_BSDF_COMPILE_AREA)
                TomBSDFLayers noLayers = (TomBSDFLayers)0;
                noLayers.ior = 1.0; noLayers.film.incidentIOR = 1.0;
                noLayers.film.filmIOR = 1.0; noLayers.film.dielectricIOR = 1.0;
                reflection += TomEvaluateRectLights(s.material, s.geometry, s.energy, noLayers, false);
            #endif
            TomGlassScreenHit hit = TomGlassFindBackground(s);
            color = reflection * s.transport.reflectionScale + s.material.emission;
            float fog = 1.0;
            #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
                UNITY_CALC_FOG_FACTOR_RAW(i.fogCoord.x);
                fog = saturate(unityFogFactor);
            #endif
            // The opaque snapshot is already fogged. Fog only the surface and
            // restore the foreground fog that transmission would otherwise tint.
            color = color * fog + s.transport.transmission * TomGlassBackgroundColor(s, hit) * hit.weight
                + (1.0 - s.transport.transmission) * unity_FogColor.rgb * (1.0 - fog);
            if (_DebugView > 0.5 && _DebugView < 1.5) color = s.transport.reflection;
            else if (_DebugView > 1.5 && _DebugView < 2.5) color = s.transport.transmission;
            else if (_DebugView > 2.5 && _DebugView < 3.5) color = hit.weight.xxx;
            else if (_DebugView > 3.5 && _DebugView < 4.5) color = s.geometry.normal * 0.5 + 0.5;
            else if (_DebugView > 4.5) color = attenuation.xxx;
        #else
            color = _DebugView > 0.5 ? 0.0 : reflection * s.transport.reflectionScale;
            #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
                UNITY_CALC_FOG_FACTOR_RAW(i.fogCoord.x);
                color *= saturate(unityFogFactor);
            #endif
        #endif
        return float4(TomSceneOutput(color) * s.coverage, 0.0);
    #endif
}
#endif
