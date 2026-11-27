#ifndef TOM_REFLECTION_TIERS_INCLUDED
#define TOM_REFLECTION_TIERS_INCLUDED
// One call per lobe. Inputs are decoded linear incident radiance, before BRDF,
// specular visibility and material reflection intensity. Unaccepted sky is black.
float3 TomReflectionTiers(float enabled, float3 planar, float planeAcceptance,
    float4 screen, float screenWeight, float3 probe, float probeAcceptance,
    float3 sky, float skyAcceptance)
{
    if (enabled < 0.5) return 0;
    float3 env = lerp(sky * saturate(skyAcceptance), probe, saturate(probeAcceptance));
    env = lerp(env, screen.rgb, saturate(screenWeight) * saturate(screen.a));
    return lerp(env, planar, saturate(planeAcceptance));
}
#endif
