#ifndef TOM_BSDF_METAL_OPTICS_INCLUDED
#define TOM_BSDF_METAL_OPTICS_INCLUDED
#include "TomBSDFTypes.cginc"

// Air-interface F0 plus neutral edge tint, using the Gulbrandsen construction.
// This is an artist-facing optical fit, not measured wavelength-dependent n,k.
void TomMetalOptics(float3 airF0,out float3 n,out float3 k)
{
    float3 r=clamp(airF0,0.0,0.99999);
    n=(1.0-r)/(1.0+r);
    k=2.0*sqrt(r)/(1.0+r);
}

float3 TomConductorFresnel(float mu,float incidentIOR,float3 n,float3 k)
{
    mu=saturate(mu);
    float3 eta=n/incidentIOR,ek=k/incidentIOR;
    float c2=mu*mu,s2=1.0-c2;
    float3 t=eta*eta-ek*ek-s2;
    float3 q=sqrt(t*t+4.0*eta*eta*ek*ek);
    // q+t cancels for almost-perfect conductors at grazing incidence.
    float3 regular=0.5*(q+t),stable=2.0*eta*eta*ek*ek/max(q-t,1e-20);
    float3 a=sqrt(max(float3(t.x<0.0?stable.x:regular.x,t.y<0.0?stable.y:regular.y,
        t.z<0.0?stable.z:regular.z),0.0));
    float3 cross=2.0*mu*a;
    float3 rs=(q+c2-cross)/max(q+c2+cross,1e-12);
    float3 rp=rs*(c2*q+s2*s2-cross*s2)/max(c2*q+s2*s2+cross*s2,1e-12);
    return saturate(0.5*(rs+rp));
}
#endif
