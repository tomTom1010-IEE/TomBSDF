#ifndef TOM_BSDF_LAYERS_INCLUDED
#define TOM_BSDF_LAYERS_INCLUDED
#include "TomBSDFSurface.cginc"
#include "../Core/TomBSDFLayerTransport.cginc"
#include "../Core/TomBSDFThinFilm.cginc"
#include "TomBSDFFilmEnergy.cginc"

struct TomLayerInputs
{
    float weight, ior, roughness, filteredRoughness;
    float3 opticalDepth;
    float baseIOR, specularWeight;
    float3 specularColor;
    float filmWeight, filmIOR, filmThickness, filmVariance, filmQuality;
};

struct TomBSDFLayers
{
    float weight, ior;
    float3 opticalDepth;
    float insideReflection;
    float3 incidentAverage;
    TomBSDFMaterial coat, substrate;
    TomBSDFGeometry coatGeometry;
    TomBSDFEnergy coatEnergy, substrateEnergy;
    float3 substrateSpecular, dielectricSpecular, substrateDiffuse, multipleScatterColor;
    TomLayerBudget budget;
    TomFilmCurve film;
};

float TomLayerMap(float value)
{
    return saturate(TomDataInput(value.xxx, _DataTextureRestore).x);
}

TomFilmCurve TomLayerFilm(TomLayerInputs p, TomBSDFMaterial m)
{
    TomFilmCurve f=(TomFilmCurve)0;
    f.plainF0=m.f0; f.plainF90=m.f90;
    f.incidentIOR=p.ior; f.filmIOR=p.filmIOR;
    f.thickness=p.filmThickness; f.thicknessVariance=p.filmVariance;
    f.dielectricIOR=p.baseIOR; f.metalness=m.metalness;
    f.dielectricScale=p.specularWeight*p.specularColor;
    TomMetalOptics(m.baseColor,f.metalN,f.metalK);
    float relative=(p.baseIOR-p.ior)/(p.baseIOR+p.ior);
    f.dielectricF0=relative*relative*p.specularWeight*p.specularColor;
    f.dielectricF90=(abs(p.baseIOR-p.ior)>1e-5 ? p.specularWeight : 0.0).xxx;
    f.weight=abs(p.filmIOR-p.ior)>1e-5 ? p.filmWeight*smoothstep(0.0,30.0,p.filmThickness) : 0.0;
    f.average=(20.0*m.f0+m.f90)/21.0;
    return f;
}

TomFilmCurve TomLayerFilmAverage(TomFilmCurve f)
{
    if(f.weight>0.0 || f.metalness>0.0)
    {
        f.average=0.0;
        [loop] for(int k=0;k<32;++k)
        {
            float mu=(k+0.5)/32.0;
            f.average+=TomSampleFilm(f,mu)*(2.0*mu/32.0);
        }
    }
    return f;
}

// Production and GPU audit share texture-free preparation. Sampling and normal
// derivatives stay in the material reader below.
TomBSDFLayers TomPrepareLayers(TomLayerInputs p, TomBSDFMaterial intrinsic,
    TomBSDFGeometry g, TomBSDFGeometry coatGeometry, float normalVariance,
    float rotationVariance, float3 aaControls)
{
    TomBSDFLayers s;
    s.weight=p.weight; s.ior=p.ior; s.opticalDepth=p.opticalDepth;
    s.coatGeometry=coatGeometry;
    s.coat=intrinsic;
    float f0=(p.ior-1.0)/(p.ior+1.0);
    s.coat.f0=(f0*f0).xxx;
    s.coat.f90=(p.ior>1.00001 ? 1.0 : 0.0).xxx;
    s.coat.metalness=1.0; s.coat.anisotropy=0.0;
    s.coat.roughness=p.filteredRoughness;
    s.coatEnergy=TomReadEnergy(saturate(dot(coatGeometry.normal,g.view)),s.coat.roughness);
    float outsideAverage=(20.0*s.coat.f0.x+s.coat.f90.x)/21.0;

    TomBSDFMaterial dielectric=intrinsic, metal=intrinsic;
    float relative=(p.baseIOR-p.ior)/(p.baseIOR+p.ior);
    dielectric.f0=relative*relative*p.specularWeight*p.specularColor;
    dielectric.f90=(abs(p.baseIOR-p.ior)>1e-5 ? p.specularWeight : 0.0).xxx;
    dielectric.metalness=0.0;
    metal.f0=TomRelativeMetalF0(intrinsic.baseColor,p.ior);
    metal.f90=1.0; metal.metalness=1.0;
    float m=intrinsic.metalness;
    s.substrate=intrinsic;
    s.substrate.f0=lerp(dielectric.f0,metal.f0,m);
    s.substrate.f90=lerp(dielectric.f90,metal.f90,m);
    s.film=TomLayerFilm(p,s.substrate);

    float mu=dot(coatGeometry.normal,g.view);
    float3 attenuation=mu>0.0 ? TomCoatBeer(p.opticalDepth,TomCoatInternalCosine(mu,p.ior)) : 0.0;
    float3 loopTransmission;
    TomCoatTransportAverages(p.opticalDepth,p.ior,s.incidentAverage,loopTransmission);
    float specularity=saturate(m+(1.0-m)*dot((20.0*dielectric.f0+dielectric.f90)/21.0,float3(1.0/3.0,1.0/3.0,1.0/3.0)));
    TomBroadenSubstrate(s.substrate,p.roughness,p.ior);
    TomFilterAnisotropicRoughness(s.substrate,normalVariance,rotationVariance,
        aaControls.x,aaControls.y,aaControls.z);
    s.substrateEnergy=TomReadDirectionalEnergy(s.substrate,g,g.view);
    s.insideReflection=TomCoatInsideReflection(outsideAverage,p.ior,s.substrate.roughness,specularity);
    dielectric.roughness=s.substrate.roughness; dielectric.anisotropy=s.substrate.anisotropy;
    metal.roughness=s.substrate.roughness; metal.anisotropy=s.substrate.anisotropy;

    // Metalness mixes complete dielectric and conductor responses. Nonlinear
    // MS compensation of an already mixed F0 loses energy in intermediate metals.
    s.substrateSpecular=0.0; s.dielectricSpecular=0.0; s.multipleScatterColor=0.0;
    if(m<1.0)
    {
        TomFilmCurve f=TomLayerFilm(p,dielectric);
        if(f.weight>0.0)
            s.dielectricSpecular=saturate(TomFilmQualityAlbedo(f,dielectric,g,s.substrateEnergy,p.filmQuality));
        else
        {
            f=TomLayerFilmAverage(f);
            s.dielectricSpecular=saturate(TomSpecularAlbedo(dielectric,s.substrateEnergy));
        }
        s.substrateSpecular+=(1.0-m)*s.dielectricSpecular;
        s.multipleScatterColor+=(1.0-m)*(f.weight>0.0 ? TomFilmMultipleColor(f,s.substrateEnergy)
            : TomMultiScatterColor(dielectric,s.substrateEnergy));
    }
    if(m>0.0)
    {
        TomFilmCurve f=TomLayerFilm(p,metal);
        float3 albedo;
        if(f.weight>0.0)
            albedo=TomFilmQualityAlbedo(f,metal,g,s.substrateEnergy,p.filmQuality);
        else {f=TomLayerFilmAverage(f);albedo=TomFilmAlbedo(f,metal,g,s.substrateEnergy);}
        s.substrateSpecular+=m*saturate(albedo);
        s.multipleScatterColor+=m*TomFilmMultipleColor(f,s.substrateEnergy);
    }
    s.substrateDiffuse=(1.0-m)*(1.0-s.dielectricSpecular)
        * TomEONAlbedo(saturate(dot(g.normal,g.view)),intrinsic.diffuseRoughness,intrinsic.baseColor);
    float3 bottom=s.substrateSpecular+s.substrateDiffuse;
    float3 roundTrip=s.insideReflection*bottom*loopTransmission;
    s.budget.escape=(1.0-s.insideReflection)*attenuation/max(1.0-roundTrip,1e-6);
    s.budget.substrate=(1.0-TomSpecularAlbedo(s.coat,s.coatEnergy))*s.incidentAverage*bottom*s.budget.escape;
    s.budget.loopGain=roundTrip/max(1.0-roundTrip,1e-6);
    return s;
}

TomBSDFGeometry TomReadCoatGeometry(TomSurfaceCoordinates c, TomBSDFGeometry baseGeometry)
{
    TomBSDFGeometry g=baseGeometry;
    float3 n=TomDecodeNormal(TomSampleSurfaceData(_CoatNormalMap,sampler_RoughnessMap,_CoatNormalMap_ST,c),
        _CoatNormalEncoding,_CoatNormalScale,_CoatNormalFlipY,_CoatNormalDataRestore);
    float3 smooth=g.smoothNormal;
    float3 t=TomSafeNormalize(g.tangent-(smooth+g.normal)
        * dot(g.tangent,smooth)/max(1.0+dot(smooth,g.normal),1e-5));
    float signB=dot(cross(g.normal,g.tangent),g.bitangent)<0.0 ? -1.0 : 1.0;
    float3 b=cross(smooth,t)*signB;
    float3 baseTS=float3(dot(g.normal,t),dot(g.normal,b),dot(g.normal,smooth));
    baseTS=TomSafeNormalize(lerp(float3(0,0,1),baseTS,saturate(_CoatNormalBaseBlend)));
    n=TomBlendNormalRNM(baseTS,n);
    g.normal=TomSafeNormalize(t*n.x+b*n.y+smooth*n.z);
    g.tangent=TomSafeNormalize(t-(smooth+g.normal)*dot(t,g.normal)/max(1.0+dot(smooth,g.normal),1e-5));
    g.bitangent=cross(g.normal,g.tangent)*signB;
    return g;
}

TomBSDFGeometry TomReadCoatGeometry(float2 uv, TomBSDFGeometry baseGeometry)
{
    return TomReadCoatGeometry(TomUnshiftedCoordinates(uv), baseGeometry);
}

TomBSDFLayers TomReadLayers(TomSurfaceCoordinates c, TomBSDFMaterial intrinsic, TomBSDFGeometry g,
    TomBSDFGeometry normalFrame, float normalVariance, float rotationVariance)
{
    TomLayerInputs p;
    p.weight=saturate(_CoatWeight)*TomLayerMap(TomSampleSurfaceData(_CoatMask,sampler_RoughnessMap,_CoatMask_ST,c).r);
    p.ior=max(_CoatIOR,1.0);
    p.roughness=saturate(_CoatRoughness*TomLayerMap(TomSampleSurfaceData(_CoatRoughnessMap,sampler_RoughnessMap,_CoatRoughnessMap_ST,c).r));
    float thickness=max(_CoatThickness,0.0)*TomLayerMap(TomSampleSurfaceData(_CoatThicknessMap,sampler_RoughnessMap,_CoatThicknessMap_ST,c).r);
    float3 tint=saturate(TomColorInput(_CoatAbsorptionColor.rgb,_ColorValueMode));
    p.opticalDepth=-log(max(tint,1e-6))*thickness/max(_CoatAbsorptionDistance,1e-4);
    TomBSDFGeometry coat=TomReadCoatGeometry(c,normalFrame);
    p.filteredRoughness=TomFilterSpecularRoughness(p.roughness,ddx(coat.normal),ddy(coat.normal),
        _SpecularAAStrength,_SpecularAAVariance,_SpecularAAThreshold);
    p.baseIOR=max(_IOR,1.0); p.specularWeight=saturate(_SpecularWeight);
    p.specularColor=saturate(TomColorInput(_SpecularColor.rgb,_ColorValueMode));
    p.filmThickness=max(_ThinFilmThickness,0.0)*TomLayerMap(TomSampleSurfaceData(_ThinFilmThicknessMap,sampler_RoughnessMap,_ThinFilmThicknessMap_ST,c).r);
    p.filmVariance=(pow(ddx(p.filmThickness),2.0)+pow(ddy(p.filmThickness),2.0))/12.0;
    p.filmIOR=max(_ThinFilmIOR,1.0);
    p.filmWeight=saturate(_ThinFilmWeight)*TomLayerMap(TomSampleSurfaceData(_ThinFilmMask,sampler_RoughnessMap,_ThinFilmMask_ST,c).r);
    p.filmQuality=_ThinFilmQuality;
    return TomPrepareLayers(p,intrinsic,g,coat,normalVariance,rotationVariance,
        float3(_SpecularAAStrength,_SpecularAAVariance,_SpecularAAThreshold));
}

TomBSDFLayers TomReadLayers(float2 uv, TomBSDFMaterial intrinsic, TomBSDFGeometry g,
    TomBSDFGeometry normalFrame, float normalVariance, float rotationVariance)
{
    return TomReadLayers(TomUnshiftedCoordinates(uv), intrinsic, g, normalFrame, normalVariance, rotationVariance);
}
#endif
