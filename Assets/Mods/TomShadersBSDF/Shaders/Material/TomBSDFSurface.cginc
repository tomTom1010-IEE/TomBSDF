#ifndef TOM_BSDF_SURFACE_INCLUDED
#define TOM_BSDF_SURFACE_INCLUDED
#include "TomBSDFInputs.cginc"
#include "TomBSDFAnisotropicEnergy.cginc"
#include "../Core/TomBSDFBRDF.cginc"
#include "../Core/TomBSDFNormalFiltering.cginc"
#include "../Platform/Unity2019/TomBSDFColor.cginc"

TomBSDFEnergy TomReadEnergy(float mu, float roughness)
{
    // Contract v1: 65 nodes including endpoints, RGBAFloat, no mip, clamp.
    float2 uv = (float2(pow(saturate(mu), 1.0 / 3.0), sqrt(saturate(roughness))) * 64.0 + 0.5) / 65.0;
    float3 value = tex2Dlod(_TomBSDFEnergyLUT, float4(uv, 0, 0)).rgb;
    TomBSDFEnergy e;
    e.dfg = value.rg;
    e.missingAverage = value.b;
    return e;
}

TomBSDFEnergy TomReadDirectionalEnergy(TomBSDFMaterial m, TomBSDFGeometry g, float3 direction)
{
    float mu = saturate(dot(g.normal, direction));
    if (m.anisotropy <= 0.0) return TomReadEnergy(mu, m.roughness);
    return TomReadAnisotropicEnergy(mu, m.roughness, m.anisotropy,
        float2(dot(g.tangent, direction), dot(g.bitangent, direction)));
}

float3 TomDecodeNormal(float4 packed, float encoding, float scale, float flipY, float restore)
{
    float3 n;
    if (encoding < 0.5)
        n = UnpackNormal(packed);
    else
    {
        packed.rgb = TomDataInput(packed.rgb, restore);
        if (encoding < 1.5)
            n = packed.rgb * 2.0 - 1.0;
        else
        {
            n.xy = packed.ag * 2.0 - 1.0;
            n.z = sqrt(saturate(1.0 - dot(n.xy, n.xy)));
        }
    }
    n.xy *= scale;
    n.y *= flipY > 0.5 ? -1.0 : 1.0;
    // Scale zero must return a neutral normal for every supported encoding.
    if (scale == 0.0) return float3(0, 0, 1);
    return TomSafeNormalize(float3(n.xy, max(n.z, 1e-5)));
}

float3 TomReadNormal(TomSurfaceCoordinates c)
{
    float3 normal = TomDecodeNormal(TomSampleSurface(_NormalMap, _NormalMap_ST, c),
        _NormalEncoding, _NormalMapScale, _NormalFlipY, _NormalDataRestore);
    // Uniform, keyword-free control: MaterialEditor can disable detail sampling.
    if (_DetailNormalMapScale <= 0.0) return normal;
    float3 detail = TomDecodeNormal(TomSampleSurface(_NormalMapDetail, _NormalMapDetail_ST, c),
        _DetailNormalEncoding, _DetailNormalMapScale, _DetailNormalFlipY, _DetailNormalDataRestore);
    return TomBlendNormalRNM(normal, detail);
}

float3 TomReadNormal(float2 uv) { return TomReadNormal(TomUnshiftedCoordinates(uv)); }

TomBSDFMaterial TomReadMaterial(TomSurfaceCoordinates c)
{
    TomBSDFMaterial m;
    float3 color = TomColorInput(TomSampleSurface(_MainTex, _MainTex_ST, c).rgb, _ColorTextureMode);
    m.baseColor = saturate(color * TomColorInput(_BaseColor.rgb, _ColorValueMode));
    float3 maps;
    if (_UseORM > 0.5)
        maps = TomDataInput(TomSampleSurface(_ORMMap, _ORMMap_ST, c).rgb, _DataTextureRestore);
    else
    {
        maps.r = TomSampleSurface(_OcclusionMap, _OcclusionMap_ST, c).r;
        maps.g = TomSampleSurfaceData(_RoughnessMap, sampler_RoughnessMap, _RoughnessMap_ST, c).r;
        maps.b = TomSampleSurface(_MetallicMap, _MetallicMap_ST, c).r;
        maps = TomDataInput(maps, _DataTextureRestore);
    }
    m.metalness = saturate(_Metallic * maps.b);
    m.roughness = saturate(_Roughness * maps.g);
    m.anisotropy = 0.0;
    m.anisotropyRotation = 0.0;
    if (_Anisotropy > 0.0)
    {
        float amount = TomSampleSurfaceData(_AnisotropyMap, sampler_RoughnessMap, _AnisotropyMap_ST, c).r;
        float rotation = TomSampleSurfaceData(_AnisotropyRotationMap, sampler_RoughnessMap, _AnisotropyRotationMap_ST, c).r;
        float2 data = TomDataInput(float3(amount, rotation, 0), _DataTextureRestore).xy;
        m.anisotropy = saturate(_Anisotropy * data.x);
        m.anisotropyRotation = (_AnisotropyRotation / 360.0 + data.y) * (2.0 * TOM_BSDF_PI);
    }
    m.diffuseRoughness = saturate(_DiffuseRoughness);
    m.occlusion = lerp(1.0, saturate(_Occlusion * maps.r), saturate(_OcclusionStrength));
    float eta = max(_IOR, 1.0);
    float f = (eta - 1.0) / (eta + 1.0);
    float weight = saturate(_SpecularWeight);
    float3 specColor = saturate(TomColorInput(_SpecularColor.rgb, _ColorValueMode));
    m.f0 = lerp(f * f * weight * specColor, m.baseColor, m.metalness);
    m.f90 = lerp(weight * (eta > 1.00001 ? 1.0 : 0.0), 1.0, m.metalness).xxx;
    m.emission = TomColorInput(TomSampleSurface(_EmissionMask, _EmissionMask_ST, c).rgb, _ColorTextureMode)
        * TomColorInput(_EmissionColor.rgb, _ColorValueMode) * max(_EmissionIntensity, 0.0);
    return m;
}

TomBSDFMaterial TomReadMaterial(float2 uv) { return TomReadMaterial(TomUnshiftedCoordinates(uv)); }

TomBSDFGeometry TomReadGeometry(float3 position, float3 smoothNormal, float4 tangent,
    TomSurfaceCoordinates c, float faceSign)
{
    TomBSDFGeometry g;
    g.position = position;
    float3 smooth = TomSafeNormalize(smoothNormal);
    float3 ng = TomSafeNormalize(cross(ddy(position), ddx(position)));
    ng *= dot(ng, smooth) < 0.0 ? -1.0 : 1.0;
    g.view = TomSafeNormalize(lerp(UnityWorldSpaceViewDir(position), UNITY_MATRIX_V[2].xyz, unity_OrthoParams.w));
    // Use the geometric hemisphere to orient two-sided frames; VFACE alone
    // reverses a mirrored transform whose inverse-transpose normal did not flip.
    faceSign = dot(ng, g.view) < 0.0 ? -1.0 : 1.0;
    float3 t = tangent.xyz - smooth * dot(tangent.xyz, smooth);
    float handedness = tangent.w;
    if (dot(t, t) < 1e-8)
    {
        float2 dx = ddx(c.originalUV), dy = ddy(c.originalUV);
        float determinant = dx.x * dy.y - dx.y * dy.x;
        if (abs(determinant) > 1e-12)
        {
            float3 dpdx = ddx(position), dpdy = ddy(position);
            t = (dpdx * dy.y - dpdy * dx.y) / determinant;
            float3 recoveredB = (dpdy * dx.x - dpdx * dy.x) / determinant;
            t -= smooth * dot(t, smooth);
            handedness = dot(cross(smooth, t), recoveredB) < 0.0 ? -1.0 : 1.0;
        }
        else
        {
            t = cross(abs(smooth.z) < 0.999 ? float3(0,0,1) : float3(0,1,0), smooth);
            handedness = 1.0;
        }
    }
    t = TomSafeNormalize(t);
    float3 b = cross(smooth, t) * handedness;
    float3 n = TomReadNormal(c);
    g.smoothNormal = smooth * faceSign;
    g.geometricNormal = ng * faceSign;
    g.normal = TomSafeNormalize(t * n.x + b * n.y + smooth * n.z) * faceSign;
    // Minimal rotation transports the UV tangent onto the perturbed normal.
    // Retain UV/transform handedness, including mirrored and two-sided meshes.
    g.tangent = TomSafeNormalize(t - (g.smoothNormal + g.normal)
        * (dot(t, g.normal) / max(1.0 + dot(g.smoothNormal, g.normal), 1e-5)));
    g.bitangent = cross(g.normal, g.tangent) * (handedness < 0.0 ? -1.0 : 1.0) * faceSign;
    return g;
}

TomBSDFGeometry TomReadGeometry(float3 position, float3 smoothNormal, float4 tangent,
    float2 uv, float faceSign)
{
    return TomReadGeometry(position, smoothNormal, tangent, TomUnshiftedCoordinates(uv), faceSign);
}
#endif
