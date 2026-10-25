#ifndef TOM_BSDF_THIN_FILM_INCLUDED
#define TOM_BSDF_THIN_FILM_INCLUDED
#include "TomBSDFTypes.cginc"
#include "TomBSDFMetalOptics.cginc"
#include "TomBSDFThinFilmRGB.cginc"

// Original implementation of a band-integrated Airy series. The four Gaussian
// XYZ sensitivity fits are mathematical data from Belcour/Barla SIGGRAPH 2017.
// No HDRP include or runtime dependency. Optical path differences are in nm.
float3 TomFilmSensitivity(float opdNM, float phaseShift, float opdVarianceNM)
{
    float phase = 2.0 * TOM_BSDF_PI * opdNM * 1e-9;
    float3 frequency = float3(1.6810e6, 1.7953e6, 2.2084e6);
    float3 variance = float3(4.3278e9, 9.3046e9, 6.6121e9);
    float3 amplitude = float3(5.4856e-13, 4.4201e-13, 5.2481e-13);
    float3 xyz = amplitude * sqrt(2.0 * TOM_BSDF_PI * variance)
        * exp(-variance * phase * phase) * cos(frequency * phase + phaseShift)
        * exp(-0.5 * (2.0 * TOM_BSDF_PI * 1e-9) * (2.0 * TOM_BSDF_PI * 1e-9)
            * frequency * frequency * opdVarianceNM);
    float extraFrequency = 2.2399e6;
    xyz.x += 9.7470e-14 * sqrt(2.0 * TOM_BSDF_PI * 4.5282e9)
        * exp(-4.5282e9 * phase * phase) * cos(extraFrequency * phase + phaseShift)
        * exp(-0.5 * pow(2.0 * TOM_BSDF_PI * 1e-9 * extraFrequency, 2.0) * opdVarianceNM);
    xyz /= 1.0685e-7;
    return float3(dot(xyz, float3(3.2406,-1.5372,-0.4986)),
        dot(xyz, float3(-0.9689,1.8758,0.0415)), dot(xyz, float3(0.0557,-0.2040,1.0570)));
}

float2 TomComplexDivide(float2 a, float2 b)
{
    return float2(dot(a,b), a.y*b.x-a.x*b.y) / max(dot(b,b),1e-20);
}
float2 TomComplexSqrt(float2 z)
{
    float r = length(z);
    return float2(sqrt(max(0.5*(r+z.x),0.0)), (z.y < 0.0 ? -1.0 : 1.0)*sqrt(max(0.5*(r-z.x),0.0)));
}

float TomFilmPolarized(float r12, float2 r23, float opd, float opdVariance, int channel)
{
    float first = r12*r12;
    float second = min(dot(r23,r23),1.0);
    float product = min(first*second,0.999999);
    float remaining = (1.0-first)*(1.0-second)/max(1.0-product,1e-6);
    float result = 1.0-remaining;
    float coefficient = -remaining;
    // A non-reflecting interface has no phase; atan2(0,0) is undefined in HLSL.
    float2 phaseAmplitude = second > 0.0 ? r23 : float2(1,0);
    float phase = atan2(phaseAmplitude.y,phaseAmplitude.x) + (r12 < 0.0 ? TOM_BSDF_PI : 0.0);
    // Spectral integration damps high orders; sixteen harmonics are a controlled
    // approximation, not evaluation at three representative wavelengths.
    [loop] for (int order=1;order<=16;++order)
    {
        coefficient *= -sqrt(product);
        if(abs(coefficient)<1e-6 || order*opd>16000.0) break;
        float3 response = TomFilmSensitivity(order*opd,order*phase,order*order*opdVariance);
        result += 2.0*coefficient*response[channel];
    }
    return result;
}

float TomFilmChannel(float mu, float incidentIOR, float filmIOR, float2 bottomIOR,
    float thicknessNM, float thicknessVariance, int channel)
{
    float sinSquared = incidentIOR*incidentIOR*(1.0-mu*mu);
    float filmCosSquared = 1.0-sinSquared/(filmIOR*filmIOR);
    if (filmCosSquared <= 0.0) return 1.0;
    float filmCos = sqrt(filmCosSquared);
    float2 nSquared = float2(bottomIOR.x*bottomIOR.x-bottomIOR.y*bottomIOR.y,2.0*bottomIOR.x*bottomIOR.y);
    float2 q = TomComplexSqrt(nSquared-float2(sinSquared,0));
    float firstS = (incidentIOR*mu-filmIOR*filmCos)/max(incidentIOR*mu+filmIOR*filmCos,1e-6);
    float firstP = (filmIOR*mu-incidentIOR*filmCos)/max(filmIOR*mu+incidentIOR*filmCos,1e-6);
    float2 secondS = TomComplexDivide(float2(filmIOR*filmCos,0)-q,float2(filmIOR*filmCos,0)+q);
    float2 secondP = TomComplexDivide(nSquared*filmCos-filmIOR*q,nSquared*filmCos+filmIOR*q);
    float opticalFactor = 2.0*filmIOR*filmCos;
    float opd = opticalFactor*thicknessNM;
    float variance = opticalFactor*opticalFactor*thicknessVariance;
    return 0.5*(TomFilmPolarized(firstS,secondS,opd,variance,channel)
        +TomFilmPolarized(firstP,secondP,opd,variance,channel));
}

struct TomFilmCurve
{
    float weight;
    float3 plainF0;
    float3 plainF90;
    float3 average;
    float incidentIOR, filmIOR, thickness, thicknessVariance;
    float dielectricIOR, metalness;
    float3 dielectricScale, metalN, metalK;
    float3 dielectricF0, dielectricF90;
};

float3 TomSampleFilm(TomFilmCurve film, float mu)
{
    float3 plain=(1.0-film.metalness)*TomFresnel(mu,film.dielectricF0,film.dielectricF90);
    if(film.metalness>0.0)
        plain+=film.metalness*TomConductorFresnel(mu,film.incidentIOR,film.metalN,film.metalK);
    if(film.weight<=0.0)return plain;
    // Evaluate the same spectral channels in lanes, avoiding a dynamic channel
    // loop nested inside the reference integration and Airy harmonic loops.
    float3 dielectric = 0.0, metal = 0.0;
    if(film.metalness<1.0)
        dielectric=TomFilmChannelsRGB(max(mu,1e-4),film.incidentIOR,film.filmIOR,
            film.dielectricIOR.xxx,0.0,film.thickness,film.thicknessVariance)*film.dielectricScale;
    if(film.metalness>0.0)
        metal=TomFilmChannelsRGB(max(mu,1e-4),film.incidentIOR,film.filmIOR,
            film.metalN,film.metalK,film.thickness,film.thicknessVariance);
    float3 value = lerp(saturate(dielectric),saturate(metal),film.metalness);
    return lerp(plain,value,film.weight);
}

// Visible-normal sampling (Heitz 2018); fixed samples, no frame-dependent noise.
float3 TomLayerVNDF(float3 v, float2 axes, float2 u)
{
    float3 vh=TomSafeNormalize(float3(axes*v.xy,v.z));
    float lensq=dot(vh.xy,vh.xy);
    float3 t1=lensq>1e-10 ? float3(-vh.y,vh.x,0)*rsqrt(max(lensq,1e-10)) : float3(1,0,0);
    float3 t2=cross(vh,t1);
    float r=sqrt(u.x), phi=2.0*TOM_BSDF_PI*u.y;
    float x=r*cos(phi), y=r*sin(phi);
    float blend=0.5*(1.0+vh.z);
    y=lerp(sqrt(max(1.0-x*x,0.0)),y,blend);
    float3 nh=x*t1+y*t2+sqrt(max(1.0-x*x-y*y,0.0))*vh;
    return TomSafeNormalize(float3(axes*nh.xy,max(nh.z,0.0)));
}

float3 TomFilmDirectionalSingle(TomFilmCurve film, TomBSDFMaterial m, TomBSDFGeometry g,
    float3 direction, TomBSDFEnergy e)
{
    float3 v=TomInAnisotropicFrame(g,direction);
    v.z=max(v.z,1e-4);v=TomSafeNormalize(v);
    float2 axes=TomAnisotropicAxes(m.roughness,m.anisotropy);
    float lambdaV=0.5*(length(float3(axes*v.xy,v.z))/v.z-1.0);
    float3 sum=0;float weights=0;
    // Joint furnace scans expose critical-angle aliasing at 32 samples.
    // Keep this loop dynamic; unrolling the Airy evaluation overwhelms FXC.
    float quality=film.incidentIOR>film.filmIOR
        ? smoothstep(0.5,0.75,m.roughness)*smoothstep(0.5,0.8,m.anisotropy) : 0.0;
    uint count=film.weight>0.0 ? (uint)(256.0+256.0*quality+0.5) : 64;
    [loop] for (uint j=0;j<count;++j)
    {
        float radical=(float)reversebits(j)*2.3283064365386963e-10;
        float3 h=TomLayerVNDF(v,axes,float2((j+0.5)/(float)count,radical));
        float vh=saturate(dot(v,h));float3 l=2.0*vh*h-v;
        if(l.z>0.0)
        {
            float lambdaL=0.5*(length(float3(axes*l.xy,l.z))/l.z-1.0);
            float w=(1.0+lambdaV)/(1.0+lambdaV+lambdaL);
            weights+=w;sum+=w*TomSampleFilm(film,vh);
        }
    }
    // Control variate: the existing accurate geometric E table makes F=1 exact.
    return sum/max(weights,1e-6)*(e.dfg.x+e.dfg.y);
}

float3 TomFilmMultipleColor(TomFilmCurve film, TomBSDFEnergy e)
{
    return film.average*film.average*(1.0-e.missingAverage)/max(1.0-film.average*e.missingAverage,1e-6);
}

float3 TomFilmAlbedo(TomFilmCurve film, TomBSDFMaterial m, TomBSDFGeometry g, TomBSDFEnergy e)
{
    return TomFilmDirectionalSingle(film,m,g,g.view,e)
        +TomFilmMultipleColor(film,e)*saturate(1.0-e.dfg.x-e.dfg.y);
}
#endif
