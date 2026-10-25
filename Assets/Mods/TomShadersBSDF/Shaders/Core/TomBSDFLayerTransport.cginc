#ifndef TOM_BSDF_LAYER_TRANSPORT_INCLUDED
#define TOM_BSDF_LAYER_TRANSPORT_INCLUDED
#include "TomBSDFBRDF.cginc"
#include "TomBSDFMetalOptics.cginc"

// Directional adding-doubling closure, not a second microfacet MS term.
// Every coefficient is an energy fraction. Thickness/distance use the same unit.
float TomCoatInternalCosine(float mu, float eta)
{
    return sqrt(max(1.0 - (1.0 - mu * mu) / (eta * eta), 1e-6));
}

float3 TomCoatBeer(float3 opticalDepth, float muInside)
{
    return exp(-opticalDepth / max(muInside, 1e-3));
}

struct TomLayerBudget
{
    float3 substrate;
    float3 escape;
    float3 loopGain;
};

float TomCoatInsideReflection(float outsideAverage,float eta,float baseRoughness,float specularity)
{
    float rough=1.0-(1.0-outsideAverage)/(eta*eta);
    float effective=lerp(1.0,baseRoughness,saturate(specularity));
    return lerp(outsideAverage,rough,effective);
}

void TomCoatTransportAverages(float3 depth,float eta,out float3 incident,out float3 loopTransmission)
{
    incident=1.0;loopTransmission=1.0;
    if(max(depth.x,max(depth.y,depth.z))<=1e-8)return;
    incident=0.0;loopTransmission=0.0;
    [loop] for(int i=0;i<16;++i)
    {
        float mu=(i+0.5)/16.0,weight=2.0*mu/16.0;
        incident+=weight*TomCoatBeer(depth,TomCoatInternalCosine(mu,eta));
        // Isotropic interior population includes statistically trapped rays.
        loopTransmission+=weight*exp(-2.0*depth/max(mu,1e-3));
    }
}

TomLayerBudget TomCloseLayer(float3 topReflection, float insideReflection,
    float3 bottomReflection, float3 downAbsorption, float3 upAbsorption)
{
    TomLayerBudget b;
    float3 roundTrip = insideReflection * bottomReflection * downAbsorption * upAbsorption;
    float3 inverse = rcp(max(1.0 - roundTrip, 1e-6));
    b.escape = (1.0 - insideReflection) * upAbsorption * inverse;
    b.substrate = (1.0 - topReflection) * downAbsorption * bottomReflection * b.escape;
    b.loopGain = roundTrip * inverse;
    return b;
}

// Finite slope-moment mapping: the GGX second moment itself is divergent.
// A bounded angular proxy supports alpha > 1 (OpenPBR anisotropic major axis).
float2 TomLayerVariance(float2 alpha)
{
    float2 x=alpha*alpha;
    float2 small=x*(1.0+x*(-0.5+x*(1.0/3.0-x*0.25)));
    // log(1+x) loses precision in narrow anisotropic axes in float32.
    return float2(x.x<.01 ? small.x : log(1.0+x.x),x.y<.01 ? small.y : log(1.0+x.y));
}
float2 TomLayerAlpha(float2 variance)
{
    float2 small=variance*(1.0+variance*(0.5+variance*(1.0/6.0+variance/24.0)));
    float2 x=float2(variance.x<.01 ? small.x : exp(variance.x)-1.0,
        variance.y<.01 ? small.y : exp(variance.y)-1.0);
    return sqrt(max(x,0.0));
}

void TomBroadenSubstrate(inout TomBSDFMaterial m, float coatRoughness, float eta)
{
    // Bounded RMS rough-transmission fit, calibrated against pinned lobe profiles.
    // Preserve axis ratio: this is not an exact isotropic GGX convolution.
    float base=m.roughness*m.roughness,coat=coatRoughness*coatRoughness;
    m.roughness=sqrt(sqrt(saturate(base*base+(1.0-rcp(eta))*coat*coat)));
}

float3 TomRelativeMetalF0(float3 f0, float outsideIOR)
{
    float3 n,k;TomMetalOptics(f0,n,k);
    return TomConductorFresnel(1.0,outsideIOR,n,k);
}
#endif
