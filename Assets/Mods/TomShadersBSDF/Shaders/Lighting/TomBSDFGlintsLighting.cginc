#ifndef TOM_BSDF_GLINT_LIGHTING_INCLUDED
#define TOM_BSDF_GLINT_LIGHTING_INCLUDED
#include "../Material/TomBSDFGlints.cginc"

float3 TomEvaluateGlintLight(TomBSDFMaterial m, TomBSDFGeometry g, TomBSDFEnergy ev,
    TomBSDFLight light, TomGlintFootprint footprint)
{
    [branch] if (footprint.weight<=0.0) return TomEvaluateLight(m,g,ev,light);
    float nv=dot(g.normal,g.view),nl=dot(g.normal,light.direction);
    if(nv<=0.0 || nl<=0.0 || dot(g.geometricNormal,g.view)<=0.0 || dot(g.geometricNormal,light.direction)<=0.0) return 0.0;
    TomBSDFEnergy el=TomReadDirectionalEnergy(m,g,light.direction);
    float3 h=TomSafeNormalize(g.view+light.direction);
    float2 axes=TomAnisotropicAxes(m.roughness,m.anisotropy);
    float d,visibility;
    if(m.anisotropy>0.0)
    {
        d=TomAnisotropicGGX(TomInAnisotropicFrame(g,h),axes);
        visibility=TomAnisotropicVisibility(TomInAnisotropicFrame(g,g.view),TomInAnisotropicFrame(g,light.direction),axes);
    }
    else
    {
        float alpha=max(m.roughness*m.roughness,TOM_BSDF_MIN_ALPHA);
        d=TomGGXDistribution(g.normal,h,alpha);
        visibility=TomSmithCorrelatedVisibility(nv,nl,alpha);
    }
    d=TomGlintDistribution(d,axes,TomInAnisotropicFrame(g,h),footprint,pow(m.roughness,4.0));
    float3 fresnel=TomFresnel(dot(g.view,h),m.f0,m.f90);
    float ms=saturate(1.0-ev.dfg.x-ev.dfg.y)*saturate(1.0-el.dfg.x-el.dfg.y)/max(ev.missingAverage,1e-7);
    float3 specular=d*visibility*fresnel+TOM_BSDF_INV_PI*ms*TomMultiScatterColor(m,ev);
    TomBSDFMaterial dielectric=TomDielectricPart(m);
    float3 diffuse=(1.0-m.metalness)*(1.0-saturate(TomSpecularAlbedo(dielectric,ev)))
        *TomEON(nv,nl,dot(g.view,light.direction),m.diffuseRoughness,m.baseColor);
    return (diffuse+specular)*light.radiance*(nl*light.attenuation);
}

float3 TomEvaluateGlintCoveredSpecular(TomBSDFLayers s,TomBSDFGeometry g,float3 l,
    TomBSDFEnergy el,TomGlintFootprint footprint)
{
    float3 h=TomSafeNormalize(g.view+l);
    float2 axes=TomAnisotropicAxes(s.substrate.roughness,s.substrate.anisotropy);
    float d=TomAnisotropicGGX(TomInAnisotropicFrame(g,h),axes);
    d=TomGlintDistribution(d,axes,TomInAnisotropicFrame(g,h),footprint,pow(s.substrate.roughness,4.0));
    float visibility=TomAnisotropicVisibility(TomInAnisotropicFrame(g,g.view),TomInAnisotropicFrame(g,l),axes);
    float ms=saturate(1.0-s.substrateEnergy.dfg.x-s.substrateEnergy.dfg.y)*saturate(1.0-el.dfg.x-el.dfg.y)
        /max(s.substrateEnergy.missingAverage,1e-7);
    return d*visibility*TomSampleFilm(s.film,dot(g.view,h))+TOM_BSDF_INV_PI*ms*s.multipleScatterColor;
}

float3 TomEvaluateGlintCoveredLight(TomBSDFLayers s,TomBSDFGeometry g,TomBSDFLight light,
    TomGlintFootprint footprint)
{
    if(dot(g.geometricNormal,g.view)<=0.0 || dot(g.geometricNormal,light.direction)<=0.0) return 0.0;
    TomBSDFEnergy coatL=TomReadDirectionalEnergy(s.coat,s.coatGeometry,light.direction);
    float3 coat=TomEvaluateBRDF(s.coat,s.coatGeometry,light.direction,s.coatEnergy,coatL).specular
        *saturate(dot(s.coatGeometry.normal,light.direction));
    float3 bottom=0.0;
    float nl=dot(g.normal,light.direction),nv=dot(g.normal,g.view);
    if(nl>0.0 && nv>0.0)
    {
        TomBSDFEnergy bottomL=TomReadDirectionalEnergy(s.substrate,g,light.direction);
        float3 specular=TomEvaluateGlintCoveredSpecular(s,g,light.direction,bottomL,footprint);
        float3 diffuse=(1.0-s.substrate.metalness)*(1.0-s.dielectricSpecular)
            *TomEON(nv,nl,dot(g.view,light.direction),s.substrate.diffuseRoughness,s.substrate.baseColor);
        float mu=dot(s.coatGeometry.normal,light.direction);
        float3 down=mu>0.0 ? TomCoatBeer(s.opticalDepth,TomCoatInternalCosine(mu,s.ior)) : 0.0;
        float3 scale=(1.0-TomSpecularAlbedo(s.coat,s.coatEnergy))*down*s.budget.escape;
        bottom=(specular+diffuse)*scale*nl;
    }
    return (coat+bottom)*light.radiance*light.attenuation;
}

float3 TomEvaluateGlintLayerLight(TomBSDFMaterial m,TomBSDFGeometry g,TomBSDFEnergy ev,
    TomBSDFLayers layers,TomBSDFLight light,TomGlintFootprint footprint)
{
    [branch] if(footprint.weight<=0.0) return TomEvaluateLayerLight(m,g,ev,layers,light);
    float3 covered=0.0;
    [branch] if(!(layers.weight<=0.0)) covered=TomEvaluateGlintCoveredLight(layers,g,light,footprint);
    float3 uncoated=0.0;
    [branch] if(layers.weight<=0.0 || !(layers.weight>=1.0)) uncoated=TomEvaluateGlintLight(m,g,ev,light,footprint);
    float3 result=covered;
    if(layers.weight<=0.0) result=uncoated;
    else if(!(layers.weight>=1.0)) result=lerp(uncoated,covered,layers.weight);
    return result;
}

float3 TomUnityGlintFallbackLights(TomBSDFMaterial m,TomBSDFGeometry g,TomBSDFEnergy ev,
    TomBSDFLayers layers,bool covered,float active,TomGlintFootprint footprint
    #if defined(TOM_BSDF_PARALLAX)
        ,TomHeightContext height
    #endif
)
{
    // Per-light evaluators already preserve the zero-glint smooth fallback.
    // Share its loop instead of cloning all four-light physical evaluations.
    float3 color=0.0;
    #if defined(UNITY_PASS_FORWARDBASE)
    if(active<0.5) return color;
    [loop] for(int index=0;index<4;++index)
    {
        float3 position=float3(unity_4LightPosX0[index],unity_4LightPosY0[index],unity_4LightPosZ0[index]);
        float3 delta=position-g.position;
        float d2=max(dot(delta,delta),1e-8);
        TomBSDFLight light;
        light.direction=delta*rsqrt(d2);
        light.radiance=TomUnityRadiance(unity_LightColor[index].rgb);
        light.attenuation=rcp(1.0+d2*unity_4LightAtten0[index]);
        #if defined(TOM_BSDF_PARALLAX)
            light=TomUnityHeightVisibility(light,height,float4(position,1.0));
        #endif
        [branch] if(covered) color+=TomEvaluateGlintLayerLight(m,g,ev,layers,light,footprint);
        else color+=TomEvaluateGlintLight(m,g,ev,light,footprint);
    }
    #endif
    return color;
}
#endif
