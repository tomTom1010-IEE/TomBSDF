#ifndef TOM_BSDF_OCCLUSION_INCLUDED
#define TOM_BSDF_OCCLUSION_INCLUDED

// Lagarde's empirical AO-to-specular visibility approximation. This is not
// ray-traced visibility and must never attenuate direct light or emission.
float TomSpecularAO(float nv, float ao, float perceptualRoughness)
{
    float alpha = perceptualRoughness * perceptualRoughness;
    return saturate(pow(saturate(nv) + saturate(ao), exp2(-16.0 * alpha - 1.0)) - 1.0 + ao);
}

float TomSpecularHorizon(float3 reflection, float3 geometricNormal)
{
    float horizon = saturate(1.0 + dot(reflection, geometricNormal));
    return horizon * horizon;
}

float TomIndirectSpecularVisibility(TomBSDFMaterial m, TomBSDFGeometry g)
{
    float ao = TomSpecularAO(saturate(dot(g.normal, g.view)), m.occlusion, m.roughness);
    float horizon = TomSpecularHorizon(TomSpecularReflection(m, g), g.geometricNormal);
    return lerp(1.0, ao, saturate(_SpecularOcclusionStrength))
        * lerp(1.0, horizon, saturate(_SpecularHorizonStrength));
}
#endif
