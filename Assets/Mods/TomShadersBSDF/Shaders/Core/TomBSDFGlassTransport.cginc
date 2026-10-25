#ifndef TOM_BSDF_GLASS_TRANSPORT_INCLUDED
#define TOM_BSDF_GLASS_TRANSPORT_INCLUDED

// Incoherent, locally parallel air/glass/air slab. This is a directional-energy
// closure, not a full microfacet BTDF, nested medium tracker or lens solver.
struct TomGlassTransport
{
    float3 reflection, transmission, reflectionScale;
    float3 insideDirection, exitPosition;
    float pathLength;
};

TomGlassTransport TomGlassSlab(TomBSDFGeometry g, float ior, float thickness,
    float3 attenuationColor, float referenceDistance, float3 interfaceEnergy)
{
    TomGlassTransport s;
    s.insideDirection = refract(-g.view, g.normal, rcp(max(ior, 1.0)));
    float cosine = max(-dot(s.insideDirection, g.normal), 1e-4);
    s.pathLength = max(thickness, 0.0) / cosine;
    s.exitPosition = g.position + s.insideDirection * s.pathLength;
    float3 absorption = exp(log(max(saturate(attenuationColor), 1e-6))
        * (s.pathLength / max(referenceDistance, 1e-5)));
    float3 f = saturate(interfaceEnergy);
    float3 roundTrip = f * f * absorption * absorption;
    float3 denominator = max(1.0 - roundTrip, 1e-6);
    s.transmission = (1.0 - f) * (1.0 - f) * absorption / denominator;
    s.reflection = f + (1.0 - f) * (1.0 - f) * f * absorption * absorption / denominator;
    s.reflectionScale = s.reflection / max(f, 1e-6);
    return s;
}
#endif
