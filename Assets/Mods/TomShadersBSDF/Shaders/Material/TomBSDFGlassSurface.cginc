#ifndef TOM_BSDF_GLASS_SURFACE_INCLUDED
#define TOM_BSDF_GLASS_SURFACE_INCLUDED
#include "TomBSDFSurface.cginc"
#include "../Core/TomBSDFGlassTransport.cginc"

Texture2D<float4> _GlassThicknessMap;
float4 _GlassThicknessMap_ST, _GlassAbsorptionColor;
float _GlassThickness, _GlassAbsorptionDistance, _UseSceneRefraction;
float _GlassDepthBias, _GlassEdgeFade;

struct TomGlassSurface
{
    TomBSDFMaterial material;
    TomBSDFGeometry geometry;
    TomBSDFEnergy energy;
    TomGlassTransport transport;
    float coverage;
};

TomGlassSurface TomReadGlassSurface(float2 uv, float3 position, float3 normal,
    float4 tangent, float facing)
{
    TomGlassSurface s = (TomGlassSurface)0;
    s.coverage = TomCoverage(uv);
    TomClipCoverage(s.coverage);
    s.geometry = TomReadGeometry(position, normal, tangent, uv, facing);
    // Glass has no painted diffuse or metallic lobe. Reuse the accepted
    // compensated GGX, normal decoding, tangent frame, anisotropy and AA.
    s.material.roughness = saturate(_Roughness * TomDataInput(
        UNITY_SAMPLE_TEX2D(_RoughnessMap, TomUV(uv, _RoughnessMap_ST)).rrr, _DataTextureRestore).r);
    if (_Anisotropy > 0.0)
    {
        float amount = _AnisotropyMap.Sample(sampler_RoughnessMap, TomUV(uv, _AnisotropyMap_ST)).r;
        float rotation = _AnisotropyRotationMap.Sample(sampler_RoughnessMap, TomUV(uv, _AnisotropyRotationMap_ST)).r;
        float2 data = TomDataInput(float3(amount, rotation, 0), _DataTextureRestore).xy;
        s.material.anisotropy = saturate(_Anisotropy * data.x);
        s.material.anisotropyRotation = (_AnisotropyRotation / 360.0 + data.y) * (2.0 * TOM_BSDF_PI);
        TomRotateAnisotropicFrame(s.geometry, s.material.anisotropyRotation);
    }
    float eta = max(_IOR, 1.0), f = (eta - 1.0) / (eta + 1.0);
    s.material.f0 = (f * f).xxx;
    s.material.f90 = (eta > 1.00001 ? 1.0 : 0.0).xxx;
    s.material.occlusion = lerp(1.0, saturate(_Occlusion * TomDataInput(
        tex2D(_OcclusionMap, TomUV(uv, _OcclusionMap_ST)).rrr, _DataTextureRestore).r), saturate(_OcclusionStrength));
    s.material.emission = TomColorInput(tex2D(_EmissionMask, TomUV(uv, _EmissionMask_ST)).rgb, _ColorTextureMode)
        * TomColorInput(_EmissionColor.rgb, _ColorValueMode) * max(_EmissionIntensity, 0.0);
    float3 dx = ddx(s.geometry.normal), dy = ddy(s.geometry.normal);
    if (_SpecularAAStrength > 0.0)
    {
        if (s.material.anisotropy > 0.0)
        {
            float rx = dot(s.geometry.bitangent, ddx(s.geometry.tangent));
            float ry = dot(s.geometry.bitangent, ddy(s.geometry.tangent));
            TomFilterAnisotropicRoughness(s.material, dot(dx, dx) + dot(dy, dy), rx * rx + ry * ry,
                _SpecularAAStrength, _SpecularAAVariance, _SpecularAAThreshold);
        }
        else s.material.roughness = TomFilterSpecularRoughness(s.material.roughness, dx, dy,
            _SpecularAAStrength, _SpecularAAVariance, _SpecularAAThreshold);
    }
    s.energy = TomReadDirectionalEnergy(s.material, s.geometry, s.geometry.view);
    float thickness = max(_GlassThickness, 0.0) * saturate(TomDataInput(
        _GlassThicknessMap.Sample(sampler_RoughnessMap, TomUV(uv, _GlassThicknessMap_ST)).rrr, _DataTextureRestore).r);
    float3 color = TomColorInput(tex2D(_MainTex, TomUV(uv, _MainTex_ST)).rgb, _ColorTextureMode)
        * TomColorInput(_BaseColor.rgb, _ColorValueMode) * TomColorInput(_GlassAbsorptionColor.rgb, _ColorValueMode);
    s.transport = TomGlassSlab(s.geometry, eta, thickness, color, _GlassAbsorptionDistance,
        TomSpecularAlbedo(s.material, s.energy));
    return s;
}
#endif
