#ifndef TOM_BSDF_LAYER_LIGHTING_INCLUDED
#define TOM_BSDF_LAYER_LIGHTING_INCLUDED
#include "../Material/TomBSDFLayers.cginc"

float3 TomLayerSubstrateScale(TomBSDFLayers s)
{
    return s.budget.substrate / max(s.substrateSpecular + s.substrateDiffuse, 1e-6);
}

float3 TomEvaluateCoveredSpecular(TomBSDFLayers s, TomBSDFGeometry g, float3 l, TomBSDFEnergy el)
{
    float3 h=TomSafeNormalize(g.view+l);
    float2 axes=TomAnisotropicAxes(s.substrate.roughness,s.substrate.anisotropy);
    float d=TomAnisotropicGGX(TomInAnisotropicFrame(g,h),axes);
    float visibility=TomAnisotropicVisibility(TomInAnisotropicFrame(g,g.view),TomInAnisotropicFrame(g,l),axes);
    float ms=saturate(1.0-s.substrateEnergy.dfg.x-s.substrateEnergy.dfg.y)*saturate(1.0-el.dfg.x-el.dfg.y)
        /max(s.substrateEnergy.missingAverage,1e-7);
    float3 f=TomSampleFilm(s.film,dot(g.view,h));
    return d*visibility*f+TOM_BSDF_INV_PI*ms*s.multipleScatterColor;
}

float3 TomEvaluateCoveredLight(TomBSDFLayers s, TomBSDFGeometry g, TomBSDFLight light)
{
    if (dot(g.geometricNormal, g.view) <= 0.0 || dot(g.geometricNormal, light.direction) <= 0.0) return 0.0;
    TomBSDFEnergy coatL = TomReadDirectionalEnergy(s.coat, s.coatGeometry, light.direction);
    float3 coat = TomEvaluateBRDF(s.coat, s.coatGeometry, light.direction, s.coatEnergy, coatL).specular
        * saturate(dot(s.coatGeometry.normal, light.direction));
    float3 bottom = 0.0;
    float nl = dot(g.normal, light.direction), nv = dot(g.normal, g.view);
    if (nl > 0.0 && nv > 0.0)
    {
        TomBSDFEnergy bottomL = TomReadDirectionalEnergy(s.substrate, g, light.direction);
        float3 specular = TomEvaluateCoveredSpecular(s, g, light.direction, bottomL);
        float3 diffuse = (1.0 - s.substrate.metalness) * (1.0 - s.dielectricSpecular)
            * TomEON(nv, nl, dot(g.view, light.direction), s.substrate.diffuseRoughness, s.substrate.baseColor);
        // Directional moment closure: lobe integrals carry transport energy;
        // normalized GGX/EON distributions carry angular shape. Not exact
        // reciprocal refractive path tracing (see Layering-Contract.md).
        float mu=dot(s.coatGeometry.normal,light.direction);
        float3 down=mu>0.0 ? TomCoatBeer(s.opticalDepth,TomCoatInternalCosine(mu,s.ior)) : 0.0;
        float3 scale=(1.0-TomSpecularAlbedo(s.coat,s.coatEnergy))*down*s.budget.escape;
        bottom = (specular + diffuse) * scale * nl;
    }
    return (coat + bottom) * light.radiance * light.attenuation;
}

float3 TomEvaluateLayerLight(TomBSDFMaterial bare, TomBSDFGeometry g, TomBSDFEnergy ev,
    TomBSDFLayers s, TomBSDFLight light)
{
    // A single call site per closure keeps FXC's inlined predicate graph bounded.
    // Inverse comparisons retain the original endpoint and NaN behavior.
    float3 covered = 0.0;
    if (!(s.weight <= 0.0)) covered = TomEvaluateCoveredLight(s, g, light);
    float3 uncoated = 0.0;
    if (s.weight <= 0.0 || !(s.weight >= 1.0)) uncoated = TomEvaluateLight(bare, g, ev, light);
    float3 result = covered;
    if (s.weight <= 0.0) result = uncoated;
    else if (!(s.weight >= 1.0)) result = lerp(uncoated, covered, s.weight);
    return result;
}
#endif
