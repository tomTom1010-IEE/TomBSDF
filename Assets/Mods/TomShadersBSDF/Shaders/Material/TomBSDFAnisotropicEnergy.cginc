#ifndef TOM_BSDF_ANISOTROPIC_ENERGY_INCLUDED
#define TOM_BSDF_ANISOTROPIC_ENERGY_INCLUDED
#include "../Core/TomBSDFTypes.cginc"

Texture3D<float4> _TomBSDFAnisoEnergyLUT;
SamplerState tom_aniso_linear_clamp_sampler;

TomBSDFEnergy TomReadAnisotropicEnergy(float mu, float roughness, float anisotropy, float2 local)
{
    local = abs(local);
    float azimuth = dot(local, local) > 1e-12 ? atan2(local.y, local.x) * (2.0 / TOM_BSDF_PI) : 0.0;
    // Resolve the narrow-axis grazing boundary, especially at anisotropy=1.
    azimuth = 1.0 - pow(saturate(1.0 - azimuth), 1.0 / 3.0);
    float layer = -log2(1.0 - saturate(anisotropy) * (1023.0 / 1024.0)) * 3.2;
    float low = min(floor(layer), 31.0);
    float2 uv = (float2(pow(saturate(mu), 1.0 / 3.0), sqrt(saturate(roughness))) * float2(64, 32) + 0.5) / float2(65, 33);
    float z = low * 33.0 + azimuth * 32.0 + 0.5;
    float3 a = _TomBSDFAnisoEnergyLUT.SampleLevel(tom_aniso_linear_clamp_sampler, float3(uv, z / 1089.0), 0).rgb;
    float3 b = _TomBSDFAnisoEnergyLUT.SampleLevel(tom_aniso_linear_clamp_sampler, float3(uv, (z + 33.0) / 1089.0), 0).rgb;
    float3 value = lerp(a, b, layer - low);
    TomBSDFEnergy e;
    e.dfg = value.rg;
    e.missingAverage = value.b;
    return e;
}
#endif
