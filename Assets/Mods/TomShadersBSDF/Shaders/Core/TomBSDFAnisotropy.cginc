#ifndef TOM_BSDF_ANISOTROPY_INCLUDED
#define TOM_BSDF_ANISOTROPY_INCLUDED
#include "TomBSDFTypes.cginc"

// OpenPBR mapping preserves mean squared alpha. Regularize each axis only at
// evaluation time; a=1 is a finite approximation to a degenerate distribution.
float2 TomAnisotropicAxes(float roughness, float anisotropy)
{
    float ratio = 1.0 - saturate(anisotropy);
    float at = roughness * roughness * sqrt(2.0 / (1.0 + ratio * ratio));
    return max(float2(at, at * ratio), TOM_BSDF_MIN_ALPHA);
}

float3 TomInAnisotropicFrame(TomBSDFGeometry g, float3 direction)
{
    return float3(dot(g.tangent, direction), dot(g.bitangent, direction), dot(g.normal, direction));
}

float TomAnisotropicGGX(float3 h, float2 alpha)
{
    float3 q = float3(h.xy / alpha, h.z);
    float d = dot(q, q);
    return TOM_BSDF_INV_PI / max(alpha.x * alpha.y * d * d, 1e-20);
}

float TomAnisotropicVisibility(float3 v, float3 l, float2 alpha)
{
    float sv = length(float3(alpha * v.xy, v.z));
    float sl = length(float3(alpha * l.xy, l.z));
    return 0.5 / max(l.z * sv + v.z * sl, 1e-12);
}

void TomRotateAnisotropicFrame(inout TomBSDFGeometry g, float radians)
{
    float s, c;
    sincos(radians, s, c);
    float3 t = g.tangent;
    g.tangent = c * t + s * g.bitangent;
    g.bitangent = -s * t + c * g.bitangent;
}

// Bent-reflection-vector approximation (Revie/McAuley, described in Filament).
// Native Unity cubemaps remain isotropically prefiltered, not an exact
// anisotropic environment convolution. Energy uses the separate 4D integral.
float3 TomSpecularReflection(TomBSDFMaterial m, TomBSDFGeometry g)
{
    if (m.anisotropy <= 0.0) return reflect(-g.view, g.normal);
    float2 axes = TomAnisotropicAxes(m.roughness, m.anisotropy);
    float bend = (axes.x - axes.y) / max(axes.x + axes.y, 1e-6);
    // Project view onto the plane perpendicular to the narrow-slope axis.
    float3 projected = g.view - g.bitangent * dot(g.bitangent, g.view);
    if (dot(projected, projected) < 1e-8) return reflect(-g.view, g.normal);
    float3 bent = TomSafeNormalize(lerp(g.normal, TomSafeNormalize(projected), bend));
    return reflect(-g.view, bent);
}
#endif
