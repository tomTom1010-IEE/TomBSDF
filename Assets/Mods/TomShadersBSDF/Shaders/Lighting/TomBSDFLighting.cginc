#ifndef TOM_BSDF_LIGHTING_INCLUDED
#define TOM_BSDF_LIGHTING_INCLUDED
#include "TomBSDFOcclusion.cginc"

float3 TomEvaluateLight(TomBSDFMaterial m, TomBSDFGeometry g, TomBSDFEnergy ev, TomBSDFLight light)
{
    float nl = saturate(dot(g.normal, light.direction));
    TomBSDFEnergy el = TomReadDirectionalEnergy(m, g, light.direction);
    TomBSDFLobes lobes = TomEvaluateBRDF(m, g, light.direction, ev, el);
    return (lobes.diffuse + lobes.specular) * light.radiance * (nl * light.attenuation);
}

float3 TomEvaluateIndirect(TomBSDFMaterial m, TomBSDFGeometry g, TomBSDFEnergy ev, TomBSDFIndirect indirect)
{
    float3 specEnergy = saturate(TomSpecularAlbedo(m, ev));
    TomBSDFMaterial dielectric=TomDielectricPart(m);
    float3 dielectricEnergy=saturate(TomSpecularAlbedo(dielectric,ev));
    float3 diffuse = TomEONAlbedo(saturate(dot(g.normal, g.view)), m.diffuseRoughness, m.baseColor)
        * (1.0 - m.metalness) * (1.0 - dielectricEnergy) * indirect.irradianceOverPi * m.occlusion;
    return diffuse + indirect.prefilteredRadiance * specEnergy * TomIndirectSpecularVisibility(m, g);
}
#endif
