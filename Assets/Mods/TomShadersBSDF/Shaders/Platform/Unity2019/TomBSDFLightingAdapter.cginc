#ifndef TOM_BSDF_UNITY_LIGHTING_INCLUDED
#define TOM_BSDF_UNITY_LIGHTING_INCLUDED
#include "../../Lighting/TomBSDFLighting.cginc"
#include "TomBSDFProbeAdapter.cginc"
#include "../../Lighting/TomBSDFLayerLighting.cginc"

float3 TomUnityRadiance(float3 unityLight)
{
    // One Unity numeric light unit is pi irradiance at normal incidence. This
    // preserves Unity's white Lambert reference, not photometric lumen units.
    if (_LightColorInput > 0.5) unityLight = TomSRGBToLinear(unityLight);
    return max(unityLight, 0.0) * TOM_BSDF_PI;
}

TomBSDFLight TomUnityCurrentLight(float3 position, float combinedAttenuation)
{
    TomBSDFLight light;
    light.direction = TomSafeNormalize(UnityWorldSpaceLightDir(position));
    light.radiance = TomUnityRadiance(_LightColor0.rgb);
    light.attenuation = combinedAttenuation;
    return light;
}

#if defined(TOM_BSDF_PARALLAX)
TomBSDFLight TomUnityHeightVisibility(TomBSDFLight light, TomHeightContext height, float4 source)
{
    [branch] if (light.attenuation > 0.0 && max(light.radiance.r, max(light.radiance.g, light.radiance.b)) > 0.0)
        light.attenuation *= TomParallaxVisibility(height, source);
    return light;
}
#endif

float3 TomUnityFallbackLights(TomBSDFMaterial m, TomBSDFGeometry g, TomBSDFEnergy ev, float active
    #if defined(TOM_BSDF_PARALLAX)
        , TomHeightContext height
    #endif
)
{
    float3 value = 0.0;
    #if defined(UNITY_PASS_FORWARDBASE)
        if (active < 0.5) return value;
        // Keep four evaluations in order without cloning the full layered BRDF.
        [loop] for (int index = 0; index < 4; ++index)
        {
            float3 delta = float3(unity_4LightPosX0[index], unity_4LightPosY0[index], unity_4LightPosZ0[index]) - g.position;
            float d2 = max(dot(delta, delta), 1e-8);
            TomBSDFLight light;
            light.direction = delta * rsqrt(d2);
            light.radiance = TomUnityRadiance(unity_LightColor[index].rgb);
            light.attenuation = rcp(1.0 + d2 * unity_4LightAtten0[index]);
            #if defined(TOM_BSDF_PARALLAX)
                light = TomUnityHeightVisibility(light, height,
                    float4(unity_4LightPosX0[index], unity_4LightPosY0[index], unity_4LightPosZ0[index], 1.0));
            #endif
            value += TomEvaluateLight(m, g, ev, light);
        }
    #endif
    return value;
}

float3 TomUnityIndirect(TomBSDFMaterial m, TomBSDFGeometry g, TomBSDFEnergy ev)
{
    TomBSDFIndirect indirect;
    indirect.irradianceOverPi = TomUnityDiffuseEnvironment(g) * _IndirectDiffuseIntensity;
    indirect.prefilteredRadiance = TomUnityProbeEnvironment(m, g) * _ReflectionIntensity;
    return TomEvaluateIndirect(m, g, ev, indirect);
}

float3 TomUnityLayerFallbackLights(TomBSDFMaterial m, TomBSDFGeometry g, TomBSDFEnergy ev,
    TomBSDFLayers s, float active
    #if defined(TOM_BSDF_PARALLAX)
        , TomHeightContext height
    #endif
)
{
    float3 value = 0.0;
    #if defined(UNITY_PASS_FORWARDBASE)
        if (active < 0.5) return value;
        [loop] for (int index = 0; index < 4; ++index)
        {
            float3 delta = float3(unity_4LightPosX0[index], unity_4LightPosY0[index], unity_4LightPosZ0[index]) - g.position;
            float d2 = max(dot(delta, delta), 1e-8);
            TomBSDFLight light;
            light.direction = delta * rsqrt(d2);
            light.radiance = TomUnityRadiance(unity_LightColor[index].rgb);
            light.attenuation = rcp(1.0 + d2 * unity_4LightAtten0[index]);
            #if defined(TOM_BSDF_PARALLAX)
                light = TomUnityHeightVisibility(light, height,
                    float4(unity_4LightPosX0[index], unity_4LightPosY0[index], unity_4LightPosZ0[index], 1.0));
            #endif
            value += TomEvaluateLayerLight(m, g, ev, s, light);
        }
    #endif
    return value;
}

float3 TomUnityLayerIndirect(TomBSDFMaterial m, TomBSDFGeometry g, TomBSDFEnergy ev, TomBSDFLayers s)
{
    float3 covered = 0.0;
    if (!(s.weight <= 0.0))
    {
        float3 coatEnergy = TomSpecularAlbedo(s.coat, s.coatEnergy);
        float3 coat = TomUnityProbeEnvironment(s.coat, s.coatGeometry) * _ReflectionIntensity
            * coatEnergy * TomIndirectSpecularVisibility(s.coat, s.coatGeometry);
        float3 substrate = TomUnityProbeEnvironment(s.substrate, g) * _ReflectionIntensity
            * s.substrateSpecular * TomIndirectSpecularVisibility(s.substrate, g)
            + TomUnityDiffuseEnvironment(g) * _IndirectDiffuseIntensity * s.substrateDiffuse * m.occlusion;
        covered = coat + substrate * TomLayerSubstrateScale(s) + m.emission * s.budget.escape;
    }
    float3 uncoated = 0.0;
    if (s.weight <= 0.0 || !(s.weight >= 1.0)) uncoated = TomUnityIndirect(m, g, ev) + m.emission;
    float3 result = covered;
    if (s.weight <= 0.0) result = uncoated;
    else if (!(s.weight >= 1.0)) result = lerp(uncoated, covered, s.weight);
    return result;
}
#endif
