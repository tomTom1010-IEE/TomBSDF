#ifndef TOM_BSDF_FILM_ENERGY_INCLUDED
#define TOM_BSDF_FILM_ENERGY_INCLUDED
#include "../Core/TomBSDFThinFilm.cginc"

Texture3D<float4> _TomBSDFFilmEnergyLUT;

float TomFilmReferenceGuard(TomFilmCurve f,float roughness,float mu)
{
    float contrast=smoothstep(1.1,1.25,f.incidentIOR/f.filmIOR);
    float longCritical=f.incidentIOR>f.filmIOR ? smoothstep(400.0,800.0,f.thickness) : 0.0;
    float critical=sqrt(saturate(1.0-(f.filmIOR/f.incidentIOR)*(f.filmIOR/f.incidentIOR)));
    float narrowCritical=f.incidentIOR>f.filmIOR
        ? (1.0-smoothstep(0.15,0.35,roughness))*(1.0-smoothstep(0.02,0.08,abs(mu-critical))) : 0.0;
    return max(max(contrast,longCritical),narrowCritical);
}

float4 TomFilmKernelWeights(float3 v,TomBSDFMaterial m,int group)
{
    float phi=dot(v.xy,v.xy)>1e-12 ? atan2(abs(v.y),abs(v.x))*(2.0/TOM_BSDF_PI) : 0.0;
    phi=1.0-pow(saturate(1.0-phi),1.0/3.0);
    float a=-log2(1.0-saturate(m.anisotropy)*(1023.0/1024.0))*1.6;
    float low=min(floor(a),15.0);
    float2 uv=(float2(pow(saturate(v.z),1.0/3.0),sqrt(saturate(m.roughness)))*float2(64,16)+0.5)/float2(65,17);
    float z=group*153.0+low*9.0+phi*8.0+0.5;
    float4 first=_TomBSDFFilmEnergyLUT.SampleLevel(tom_aniso_linear_clamp_sampler,float3(uv,z/1224.0),0);
    float4 second=_TomBSDFFilmEnergyLUT.SampleLevel(tom_aniso_linear_clamp_sampler,float3(uv,(z+9.0)/1224.0),0);
    return lerp(first,second,a-low);
}

// Positive piecewise-linear basis: white stays white, and bounded Fresnel
// stays bounded without clamping the final BRDF. The LUT contains geometry only.
float3 TomFilmQualityAlbedo(inout TomFilmCurve f,TomBSDFMaterial m,TomBSDFGeometry g,TomBSDFEnergy e,float quality)
{
    float3 v=TomInAnisotropicFrame(g,g.view);
    v.z=max(v.z,1e-4);v=TomSafeNormalize(v);
    float guard=quality>=0.5 ? 1.0 : TomFilmReferenceGuard(f,m.roughness,v.z);
    float3 single=0.0,average=0.0;float normalization=0.0;
    const float step=1.0/31.0;
    if(guard<1.0)
    {
        [loop] for(int group=0;group<8;++group)
        {
            float4 weights=TomFilmKernelWeights(v,m,group);
            [loop] for(int c=0;c<4;++c)
            {
                int j=group*4+c;float mu=j*step;
                float3 value=TomSampleFilm(f,max(mu,1e-4));
                single+=weights[c]*value;normalization+=weights[c];
                float meanWeight=j==0 ? step*step/3.0 : (j==31 ? step-step*step/3.0 : 2.0*step*mu);
                average+=meanWeight*value;
            }
        }
        single=single/max(normalization,1e-6)*(e.dfg.x+e.dfg.y);
    }
    if(guard>0.0)
    {
        f.average=0.0;
        [loop] for(int j=0;j<32;++j)
        {
            float mu=(j+0.5)/32.0;
            f.average+=TomSampleFilm(f,mu)*(2.0*mu/32.0);
        }
        single=lerp(single,TomFilmDirectionalSingle(f,m,g,g.view,e),guard);
        average=lerp(average,f.average,guard);
    }
    f.average=average;
    return single+TomFilmMultipleColor(f,e)*saturate(1.0-e.dfg.x-e.dfg.y);
}
#endif
