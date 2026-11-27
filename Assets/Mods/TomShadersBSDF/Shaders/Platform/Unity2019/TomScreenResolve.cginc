#include "TomReflectionTiers.cginc"
#include "TomNativeReflectionAcceptance.cginc"
float _TomSSRNativeControls;
Texture2D<float4> _TomSSRBaseHit, _TomSSRCoatHit, _TomSSRBaseFrame, _TomSSRCoatFrame;
TextureCube<float4> _TomSSRSky, _TomSSRCubeA, _TomSSRCubeB;
float4 _TomSSRSkyDecode, _TomSSRADecode, _TomSSRBDecode;
float4 _TomSSRAPos, _TomSSRABoxMin, _TomSSRABoxMax, _TomSSRBPos, _TomSSRBBoxMin, _TomSSRBBoxMax;
float4 _TomSSRLocalWeights;  // x/y local fractions; no validity test based on brightness
float4 _TomSSRResolveSize;   // xy source, zw trace
float _ProbeWeight, _SkyWeight, _TomSSRBoundPlane;

float4 TomSSRLookup(int2 pixel,bool coat,float4 frame) {
    int2 full=(int2)_TomSSRResolveSize.xy, size=(int2)_TomSSRResolveSize.zw;
    float2 p=(pixel+.5)*size/full-.5;int2 tile=(int2)floor(p);float2 f=frac(p);
    float depth=_TomSSRSourceDepth.Load(int3(pixel,0));
    float4 sum=0;float total=0;
    [unroll] for(int j=0;j<2;j++) [unroll] for(int i=0;i<2;i++){
        int2 q=clamp(tile+int2(i,j),0,size-1);
        int2 orig=min((int2)((q+.5)*full/size),full-1);
        float4 nf=coat?_TomSSRCoatFrame.Load(int3(orig,0)):_TomSSRBaseFrame.Load(int3(orig,0));
        float z=_TomSSRSourceDepth.Load(int3(orig,0));
        float w=(i?f.x:1-f.x)*(j?f.y:1-f.y);
        w*=saturate((dot(nf.xyz,frame.xyz)-.85)/.15)*saturate(1-abs(nf.w-frame.w)*8);
        w*=saturate(1-abs(z-depth)/max(1e-5,abs(depth)*.015));
        float4 c=coat?_TomSSRCoatHit.Load(int3(q,0)):_TomSSRBaseHit.Load(int3(q,0));
        sum+=float4(c.rgb*c.a,c.a)*w;total+=w;
    }
    return float4(sum.rgb/max(sum.a,1e-6),sum.a/max(total,1e-6));
}
void TomSSRLocal(TomBSDFMaterial m,TomBSDFGeometry g,out float3 sky,out float3 local,out float share){
    float3 d=TomSpecularReflection(m,g),a=d,b=d;
    float mip=m.roughness*(1.7-.7*m.roughness)*UNITY_SPECCUBE_LOD_STEPS;
    float2 w=saturate(_TomSSRLocalWeights.xy);
    if(_ProbeBlending<.5 && w.x>0)w=float2(1,0);
    share=saturate(w.x+w.y);
    sky=TomColorInput(TomDecodeProbeHDR(_TomSSRSky.SampleLevel(tom_sh_linear_clamp_sampler,d,mip),_TomSSRSkyDecode),_ReflectionColorMode);
    local=0;
    if(w.x>0){
        if(_ProbeBoxProjection>.5 && _TomSSRAPos.w>0)a=BoxProjectedCubemapDirection(d,g.position,_TomSSRAPos,_TomSSRABoxMin,_TomSSRABoxMax);
        local+=w.x*TomColorInput(TomDecodeProbeHDR(_TomSSRCubeA.SampleLevel(tom_sh_linear_clamp_sampler,a,mip),_TomSSRADecode),_ReflectionColorMode);
    }
    if(w.y>0){
        if(_ProbeBoxProjection>.5 && _TomSSRBPos.w>0)b=BoxProjectedCubemapDirection(d,g.position,_TomSSRBPos,_TomSSRBBoxMin,_TomSSRBBoxMax);
        local+=w.y*TomColorInput(TomDecodeProbeHDR(_TomSSRCubeB.SampleLevel(tom_sh_linear_clamp_sampler,b,mip),_TomSSRBDecode),_ReflectionColorMode);
    }
    local/=max(1e-6,w.x+w.y);
}
float3 TomSSRDelta(TomBSDFMaterial m,TomBSDFGeometry g,int2 pixel,bool coat,float4 optical,float2 mask,TomSurfaceCoordinates c) {
    float4 hit=TomSSRLookup(pixel,coat,optical);
    float sw=mask.g*_SSRWeight*(coat?_SSRCoatWeight:_SSRBaseWeight);
    // The custom replay is not a native ForwardBase draw: do not inherit a
    // previous renderer's cube, decode, blend weight or box-projection state.
    float3 old,lower;
    if(_TomSSRLocalWeights.w>.5) {
        float3 sky,local;float share;TomSSRLocal(m,g,sky,local,share);
        old=lerp(sky,local,share);
        lower=TomReflectionTiers(1,0,0,0,0,local,share*_ProbeWeight,sky,_SkyWeight);
        if(_TomSSRNativeControls>.5)old=lower;
    } else {
    old=TomUnityProbeEnvironment(m,g);lower=old;
    if(_TomSSRNativeControls>.5) {
        old=TomNativeAcceptance(m,g,old,_ProbeWeight,_SkyWeight);lower=old;
    } else if(_ProbeWeight!=1 || _SkyWeight!=1) {
        float3 sky,local;float share;TomSSRLocal(m,g,sky,local,share);
        float3 expected=lerp(sky,local,share);
        float3 tolerance=.002*max(1,abs(old));
        // The authoring classifier is not authoritative for this draw yet.
        // Retain native environment on disagreement, rather than inventing a
        // bright substitute or deciding that a valid black probe is missing.
        if(all(abs(expected-old)<=tolerance))
            lower=TomReflectionTiers(1,0,0,0,0,local,share*_ProbeWeight,sky,_SkyWeight);
    }
    }
    lower=_ReflectionsEnabled<.5?0:lerp(lower,hit.rgb,saturate(sw)*hit.a);
    // The exact planar gather is affine in its fallback radiance, including
    // per-tap range rejection. Preserve its existing lobe footprint and priority.
    float pw=_TomSSRBoundPlane>0 ? TomPlanarWeight(c)*(coat?_PlanarCoatWeight:_PlanarBaseWeight) : 0;
    if(pw>0) {
        old=TomPlanarOver(m,g,pw,old);
        lower=_ReflectionsEnabled<.5?0:TomPlanarOver(m,g,pw,lower);
    }
    return (lower-old)*_ReflectionIntensity;
}
float4 TomSSRResolve(TomVertexOutput i,float front:VFACE):SV_Target {
    TomSSRVisible(i);
    if(_DebugView>.5 || _ReflectionIntensity<=0 || (_TomSSRNativeControls>.5 && _ReflectionsEnabled<.5))return 0;
    TomSurfaceCoordinates c;TomBSDFMaterial intrinsic,m;TomBSDFGeometry g,f;float nv,rv;
    TomSSRSurface(i,front,c,intrinsic,m,g,f,nv,rv);
    float2 mask=TomSampleSurfaceData(_PlanarReflectionMask,tom_sh_linear_clamp_sampler,_PlanarReflectionMask_ST,c).rg;
    int2 px=(int2)i.pos.xy;float4 bf=TomSSRFrame(m,g);
    TomBSDFEnergy ev=TomReadDirectionalEnergy(m,g,g.view);
    float3 v=TomSSRDelta(m,g,px,false,bf,mask,c)*saturate(TomSpecularAlbedo(m,ev))*TomIndirectSpecularVisibility(m,g);
    if(_CoatWeight>0) {
        TomBSDFLayers s=TomReadLayers(c,intrinsic,g,f,nv,rv);
        if(s.weight>0) {
            float3 under=TomSSRDelta(s.substrate,g,px,false,bf,mask,c)*s.substrateSpecular*TomIndirectSpecularVisibility(s.substrate,g);
            float3 top=TomSSRDelta(s.coat,s.coatGeometry,px,true,TomSSRFrame(s.coat,s.coatGeometry),mask,c)
                *TomSpecularAlbedo(s.coat,s.coatEnergy)*TomIndirectSpecularVisibility(s.coat,s.coatGeometry);
            v=lerp(v,top+under*TomLayerSubstrateScale(s),s.weight);
        }
    }
    #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
        UNITY_CALC_FOG_FACTOR_RAW(i.fogCoord.x);v*=saturate(unityFogFactor);
    #endif
    return float4(v,0);
}
