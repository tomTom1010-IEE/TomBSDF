#ifndef TOM_BSDF_NORMAL_FILTERING_INCLUDED
#define TOM_BSDF_NORMAL_FILTERING_INCLUDED

// RNM, Barre-Brisebois/Hill: rotate the detail frame onto the base normal.
float3 TomBlendNormalRNM(float3 baseNormal, float3 detailNormal)
{
    float3 t = baseNormal + float3(0, 0, 1);
    float3 u = detailNormal * float3(-1, -1, 1);
    return TomSafeNormalize(t * (dot(t, u) / max(t.z, 1e-5)) - u);
}

// Bounded isotropic NDF filtering (Tokuyoshi/Kaplanyan). Inputs are screen
// derivatives of the final unit shading normal, not encoded map colors.
float TomFilterSpecularRoughness(float roughness, float3 dx, float3 dy,
    float strength, float varianceScale, float threshold)
{
    float alpha = roughness * roughness;
    float variance = max(varianceScale, 0.0) * (dot(dx, dx) + dot(dy, dy));
    float kernel = min(2.0 * variance, threshold * threshold) * saturate(strength);
    return sqrt(sqrt(saturate(alpha * alpha + kernel)));
}

// Add the bounded isotropic footprint to BOTH squared axes, then invert the
// OpenPBR mapping. This broadens the narrow lobe instead of restoring its
// original aspect ratio after filtering. Tangent variation isotropizes the
// covariance at constant trace; a 180-degree director flip is neutral.
void TomFilterAnisotropicRoughness(inout TomBSDFMaterial m, float normalVariance,
    float rotationVariance, float strength, float varianceScale, float threshold)
{
    if (strength <= 0.0 || threshold <= 0.0) return;
    float ratio = 1.0 - m.anisotropy;
    float mean = pow(m.roughness, 4.0);
    float difference = mean * (1.0 - ratio * ratio) / (1.0 + ratio * ratio);
    float kernel = min(2.0 * max(varianceScale, 0.0) * normalVariance, threshold * threshold) * saturate(strength);
    difference *= exp(-2.0 * max(varianceScale, 0.0) * rotationVariance * saturate(strength));
    mean = min(mean + kernel, 1.0);
    float2 squaredAxes = max(float2(mean + difference, mean - difference), 0.0);
    m.roughness = sqrt(sqrt(mean));
    m.anisotropy = squaredAxes.x > 0.0 ? saturate(1.0 - sqrt(squaredAxes.y / squaredAxes.x)) : 0.0;
}
#endif
