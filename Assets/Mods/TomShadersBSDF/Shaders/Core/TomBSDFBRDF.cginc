#ifndef TOM_BSDF_BRDF_INCLUDED
#define TOM_BSDF_BRDF_INCLUDED
#include "TomBSDFTypes.cginc"
#include "TomBSDFAnisotropy.cginc"

float3 TomFresnel(float cosTheta, float3 f0, float3 f90)
{
    return lerp(f0, f90, TomPow5(1.0 - saturate(cosTheta)));
}

float TomGGXDistribution(float3 n, float3 h, float alpha)
{
    // Cross product retains precision at the mirror peak; do not clamp D's
    // denominator to 1e-4, which destroys narrow highlights.
    float3 c = cross(n, h);
    float nh = saturate(dot(n, h));
    float d = dot(c, c) + (alpha * nh) * (alpha * nh);
    float q = alpha / max(d, 1e-12);
    return q * q * TOM_BSDF_INV_PI;
}

float TomSmithCorrelatedVisibility(float nv, float nl, float alpha)
{
    float a2 = alpha * alpha;
    float gv = nl * sqrt(a2 + (1.0 - a2) * nv * nv);
    float gl = nv * sqrt(a2 + (1.0 - a2) * nl * nl);
    return 0.5 / max(gv + gl, 1e-12);
}

TomBSDFMaterial TomDielectricPart(TomBSDFMaterial m)
{
    float fraction=1.0-m.metalness;
    m.f0=saturate((m.f0-m.metalness*m.baseColor)/max(fraction,1e-6));
    m.f90=saturate((m.f90-m.metalness)/max(fraction,1e-6));
    m.metalness=0.0;
    return m;
}

float3 TomSingleMaterialMultiScatterColor(float3 f0,float3 f90,TomBSDFEnergy e)
{
    float3 favg = (20.0 * f0 + f90) / 21.0;
    return favg * favg * (1.0 - e.missingAverage)
        / max(1.0 - favg * e.missingAverage, 1e-6);
}

float3 TomMultiScatterColor(TomBSDFMaterial m, TomBSDFEnergy e)
{
    if(m.metalness>0.0 && m.metalness<1.0)
    {
        TomBSDFMaterial dielectric=TomDielectricPart(m);
        return lerp(TomSingleMaterialMultiScatterColor(dielectric.f0,dielectric.f90,e),
            TomSingleMaterialMultiScatterColor(m.baseColor,1.0,e),m.metalness);
    }
    return TomSingleMaterialMultiScatterColor(m.f0,m.f90,e);
}

float3 TomSpecularAlbedo(TomBSDFMaterial m, TomBSDFEnergy e)
{
    float missing = saturate(1.0 - e.dfg.x - e.dfg.y);
    return m.f0 * e.dfg.x + m.f90 * e.dfg.y + TomMultiScatterColor(m, e) * missing;
}

// EON (Portsmouth, Kutz, Hill), equations 10, 14, 15, 19. The polynomial is
// their directional-albedo fit. See Documents/Foundation-Contract.md.
float TomFONAlbedo(float mu, float roughness)
{
    float x = 1.0 - saturate(mu);
    float g = x * (0.0571085289 + x * (0.491881867 + x * (-0.332181442 + x * 0.0714429953)));
    return (1.0 + roughness * g) / (1.0 + (0.5 - 2.0 / (3.0 * TOM_BSDF_PI)) * roughness);
}

float TomFONAverage(float r)
{
    return (1.0 + (2.0 / 3.0 - 28.0 / (15.0 * TOM_BSDF_PI)) * r)
        / (1.0 + (0.5 - 2.0 / (3.0 * TOM_BSDF_PI)) * r);
}

float3 TomEON(float nv, float nl, float lv, float r, float3 rho)
{
    float s = lv - nv * nl;
    float st = s > 0.0 ? s / max(max(nv, nl), 1e-6) : s;
    float a = rcp(1.0 + (0.5 - 2.0 / (3.0 * TOM_BSDF_PI)) * r);
    float avg = TomFONAverage(r);
    float3 msColor = rho * rho * avg / max(1.0 - rho * (1.0 - avg), 1e-6);
    float ms = (1.0 - TomFONAlbedo(nv, r)) * (1.0 - TomFONAlbedo(nl, r)) / max(1.0 - avg, 1e-7);
    return TOM_BSDF_INV_PI * (rho * a * (1.0 + r * st) + msColor * ms);
}

float3 TomEONAlbedo(float nv, float r, float3 rho)
{
    float ef = TomFONAlbedo(nv, r);
    float avg = TomFONAverage(r);
    float3 msColor = rho * rho * avg / max(1.0 - rho * (1.0 - avg), 1e-6);
    return rho * ef + msColor * (1.0 - ef);
}

TomBSDFLobes TomEvaluateBRDF(TomBSDFMaterial m, TomBSDFGeometry g,
    float3 l, TomBSDFEnergy ev, TomBSDFEnergy el)
{
    TomBSDFLobes result;
    result.diffuse = 0.0;
    result.specular = 0.0;
    float nv = dot(g.normal, g.view);
    float nl = dot(g.normal, l);
    if (nv <= 0.0 || nl <= 0.0 || dot(g.geometricNormal, l) <= 0.0 || dot(g.geometricNormal, g.view) <= 0.0)
        return result;

    float3 h = TomSafeNormalize(g.view + l);
    float alpha = max(m.roughness * m.roughness, TOM_BSDF_MIN_ALPHA);
    float d = TomGGXDistribution(g.normal, h, alpha);
    float visibility = TomSmithCorrelatedVisibility(nv, nl, alpha);
    if (m.anisotropy > 0.0)
    {
        float2 axes = TomAnisotropicAxes(m.roughness, m.anisotropy);
        d = TomAnisotropicGGX(TomInAnisotropicFrame(g, h), axes);
        visibility = TomAnisotropicVisibility(TomInAnisotropicFrame(g, g.view), TomInAnisotropicFrame(g, l), axes);
    }
    float3 f = TomFresnel(dot(g.view, h), m.f0, m.f90);
    float ms = saturate(1.0 - ev.dfg.x - ev.dfg.y) * saturate(1.0 - el.dfg.x - el.dfg.y)
        / max(ev.missingAverage, 1e-7);
    result.specular = d * visibility * f + TOM_BSDF_INV_PI * ms * TomMultiScatterColor(m, ev);

    // Fixed-view energy closure of opaque dielectric reflection + diffuse.
    // Double-sided attenuation lost energy even on a lossless white substrate.
    // This view-side approximation trades reciprocity for furnace conservation.
    TomBSDFMaterial dielectric=TomDielectricPart(m);
    float3 substrate=1.0-saturate(TomSpecularAlbedo(dielectric,ev));
    result.diffuse = (1.0 - m.metalness) * substrate
        * TomEON(nv, nl, dot(g.view, l), m.diffuseRoughness, m.baseColor);
    return result;
}
#endif
