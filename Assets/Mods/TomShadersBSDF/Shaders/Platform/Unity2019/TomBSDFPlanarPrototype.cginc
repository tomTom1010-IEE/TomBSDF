#include "UnityCG.cginc"
#include "Lighting.cginc"
#include "AutoLight.cginc"
#include "UnityStandardUtils.cginc"
#include "../../Material/TomBSDFSurface.cginc"
#if defined(TOM_BSDF_PARALLAX)
    #include "../../Core/TomBSDFParallax.cginc"
#endif
#include "TomBSDFLightingAdapter.cginc"
#include "TomPlanarFilter.cginc"
Texture2D<float4> _PlanarReflectionMask;
float4 _PlanarReflectionMask_ST;
float _PlanarReflectionWeight,_PlanarBaseWeight,_PlanarCoatWeight,_PlanarNormalDistortion,_PlanarStretch,_PlanarReflectionGroup;
float4 _TomPlanarAxisX, _TomPlanarAxisZ;

float TomPlanarWeight(TomSurfaceCoordinates c) {
    if (_TomPlanarParams.x!=1 || _TomPlanarParams.y!=1 || (_PlanarReflectionGroup>0 && _PlanarReflectionGroup!=_TomPlanarParams.z))return 0;
    return saturate(_PlanarReflectionWeight)*TomSampleSurfaceData(_PlanarReflectionMask,tom_sh_linear_clamp_sampler,_PlanarReflectionMask_ST,c).r;
}
float3 TomPlanarRadiance(TomBSDFMaterial m,TomBSDFGeometry g,float weight) {
    float3 probe=TomUnityProbeEnvironment(m,g);
#if defined(_TOM_ENV_CONTROLS)
    if (_ReflectionsEnabled<.5) return 0;
#endif
    float height=abs(dot(_TomPlanarPlane,float4(g.position,1)))/max(.001,_TomPlanarExtentFade.z);
    weight=saturate(weight)*(1-smoothstep(.5,1,height));
    // Unbounded legacy/test planes leave extent.x at zero (or negative).
    if (_TomPlanarExtentFade.x>0 && _TomPlanarExtentFade.y>0) {
        float2 local=float2(dot(_TomPlanarAxisX,float4(g.position,1)),dot(_TomPlanarAxisZ,float4(g.position,1)));
        float2 edge=_TomPlanarExtentFade.xy-abs(local);
        float inside=min(edge.x,edge.y);
        weight*=(_TomPlanarExtentFade.w>0?smoothstep(0,_TomPlanarExtentFade.w,inside):step(0,inside));
        weight*=step(.70710678,dot(g.geometricNormal,_TomPlanarPlane.xyz));
    }
    float4 clip=mul(_TomPlanarGpuVP,float4(g.position,1));
    if(weight<=0 || clip.w<=0)return probe;
    if((_TomPlanarRange.x>0 || _TomPlanarRange.y>0) && _TomPlanarDepthParams.x<.5)return probe;
    float2 uv=TomPlanarScreen(clip);
    if(any(uv<0) || any(uv>1))return probe;
    float4 hit=0;
    if(_TomPlanarDepthParams.x>.5)hit=TomPlanarHit(uv);
    float range=hit.w>0?length(hit.xyz-g.position):max(1,clip.w)*6;
    float3 flat=reflect(-g.view,_TomPlanarPlane.xyz);
    float3 dir=reflect(-g.view,g.normal);
    float3 target=hit.w>0?hit.xyz:g.position+flat*range;
    float4 center=mul(_TomPlanarGpuVP,float4(target,1));
    if(center.w<=0)return probe;
    if(hit.w>0 && _PlanarNormalDistortion>0){
        float2 warp=TomPlanarJacobian(center,(dir-flat)*range)*_TomPlanarTexelSize.xy*_PlanarNormalDistortion;
        float amount=length(warp);
        weight*=1-smoothstep(.035,.075,amount);
        // Color, range and depth confidence must all address the same captured point.
        uv=saturate(uv+warp*min(1,.05/max(amount,1e-6)));
        weight*=TomPlanarConfidence(uv,hit,g.position,range);
    }
    float2 alpha=TomAnisotropicAxes(m.roughness,m.anisotropy);
    float nv=saturate(dot(g.view,g.normal));
    float2 u=TomPlanarJacobian(center,2*range*alpha.x*(dot(g.view,g.tangent)*g.normal+nv*g.tangent));
    float2 v=TomPlanarJacobian(center,2*range*alpha.y*(dot(g.view,g.bitangent)*g.normal+nv*g.bitangent));
    float xx=u.x*u.x+v.x*v.x, yy=u.y*u.y+v.y*v.y, xy=u.x*u.y+v.x*v.y;
    float delta=length(float2(xx-yy,2*xy)), l=.5*(xx+yy+delta);
    float2 axis=abs(xy)>1e-7?normalize(float2(xy,l-xx)):(xx>=yy?float2(1,0):float2(0,1));
    float cap=max(1,min(_TomPlanarTexelSize.z,_TomPlanarTexelSize.w)*.12);
    float minor=min(cap,sqrt(max(0,.5*(xx+yy-delta))));
    float major=min(cap,lerp(minor,sqrt(max(0,l)),clamp(_PlanarStretch,0,2)));
    return lerp(probe,TomPlanarGather(uv,axis,major,minor,hit,g.position,range,probe),weight);
}
float3 TomPlanarBase(TomBSDFMaterial m,TomBSDFGeometry g,TomBSDFEnergy ev,float w) {
    TomBSDFIndirect i;i.irradianceOverPi=TomUnityDiffuseEnvironment(g)*_IndirectDiffuseIntensity;
    i.prefilteredRadiance=TomPlanarRadiance(m,g,w*_PlanarBaseWeight)*_ReflectionIntensity;
    return TomEvaluateIndirect(m,g,ev,i);
}
float3 TomPlanarLayers(TomBSDFMaterial m,TomBSDFGeometry g,TomBSDFEnergy ev,TomBSDFLayers s,float w){
    float3 covered=0;
    [branch] if(s.weight>0){
        float3 coat=TomPlanarRadiance(s.coat,s.coatGeometry,w*_PlanarCoatWeight)*_ReflectionIntensity
            *TomSpecularAlbedo(s.coat,s.coatEnergy)*TomIndirectSpecularVisibility(s.coat,s.coatGeometry);
        float3 substrate=TomPlanarRadiance(s.substrate,g,w*_PlanarBaseWeight)*_ReflectionIntensity
            *s.substrateSpecular*TomIndirectSpecularVisibility(s.substrate,g)
            +TomUnityDiffuseEnvironment(g)*_IndirectDiffuseIntensity*s.substrateDiffuse*m.occlusion;
        covered=coat+substrate*TomLayerSubstrateScale(s)+m.emission*s.budget.escape;
    }
    if(s.weight>=1)return covered;
    float3 base=TomPlanarBase(m,g,ev,w)+m.emission;
    return s.weight<=0?base:lerp(base,covered,s.weight);
}
#define TomUnityIndirect(m,g,ev) TomPlanarBase(m,g,ev,TomPlanarWeight(coordinates))
#define TomUnityLayerIndirect(m,g,ev,s) TomPlanarLayers(m,g,ev,s,TomPlanarWeight(coordinates))
#define TomUnityProbeEnvironment(m,g) TomPlanarRadiance(m,g,TomPlanarWeight(coordinates)*_PlanarBaseWeight)
