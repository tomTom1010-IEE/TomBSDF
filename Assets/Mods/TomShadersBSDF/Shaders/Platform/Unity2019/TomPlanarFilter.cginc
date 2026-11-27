#ifndef TOM_PLANAR_FILTER_INCLUDED
#define TOM_PLANAR_FILTER_INCLUDED
#include "TomPlanarRange.cginc"
float4 _TomPlanarRange, _TomPlanarCaptureEye;
Texture2D<float4> _TomPlanarColor;
Texture2D<float> _TomPlanarDepth;
float4x4 _TomPlanarGpuVP, _TomPlanarInverseGpuVP;
float4 _TomPlanarPlane, _TomPlanarParams, _TomPlanarTexelSize, _TomPlanarExtentFade, _TomPlanarUvScaleBias, _TomPlanarDepthParams;
int _TomPlanarMipCount;

float3 TomPlanarRangeColor(float4 c,float hitWeight,float3 probe){
    // RGB and acceptance were filtered together. Cap by the local hit, not a
    // second multiplication by the same fade on homogeneous patches.
    return probe+(c.rgb-probe*c.a)*min(1,hitWeight/max(1e-7,c.a));
}
float4 TomPlanarHit(float2 uv) {
    int2 p=clamp((int2)(uv*_TomPlanarTexelSize.zw),0,(int2)_TomPlanarTexelSize.zw-1);
    float raw=_TomPlanarDepth.Load(int3(p,0));
    float4 h=mul(_TomPlanarInverseGpuVP,float4((uv-_TomPlanarUvScaleBias.zw)/_TomPlanarUvScaleBias.xy,raw,1));
    bool finite=abs(h.w)>1e-7 && abs(raw-(1-_TomPlanarDepthParams.y))>1e-7;
    return finite?float4(h.xyz/h.w,1):0;
}
float TomPlanarHitAcceptance(float2 uv){
    // Point depth and the reconstruction ray must refer to the same texel.
    // An oblique projection couples depth to XY, even on a flat wall.
    int2 p=clamp((int2)(uv*_TomPlanarTexelSize.zw),0,(int2)_TomPlanarTexelSize.zw-1);
    float4 h=TomPlanarHit((p+.5)*_TomPlanarTexelSize.xy);
    return h.w*TomPlanarRangeWeight(length(h.xyz-_TomPlanarCaptureEye.xyz),_TomPlanarRange);
}
float2 TomPlanarScreen(float4 clip) {return clip.xy/max(clip.w,1e-6)*_TomPlanarUvScaleBias.xy+_TomPlanarUvScaleBias.zw;}
float2 TomPlanarJacobian(float4 clip,float3 delta) {
    float4 d=mul(_TomPlanarGpuVP,float4(delta,0));
    return (d.xy-clip.xy/max(clip.w,1e-6)*d.w)*_TomPlanarUvScaleBias.xy*_TomPlanarTexelSize.zw/max(clip.w,1e-6);
}
float TomPlanarConfidence(float2 uv,float4 center,float3 surface,float range) {
    if(_TomPlanarDepthParams.x<.5)return 1;
    float4 hit=TomPlanarHit(uv);
    if(hit.w!=center.w)return 0;
    if(hit.w==0)return 1;
    float error=abs(length(hit.xyz-surface)-range)/max(.20,range*.20);
    return 1-smoothstep(.5,1.5,error);
}
// Elliptical quadrature in capture texels. Input axes are projected slope
// radii, not an extra roughness or Fresnel factor. Each rejected tap uses Probe.
float3 TomPlanarGather(float2 uv,float2 axis,float major,float minor,float4 hit,float3 surf,float range,float3 probe) {
    if(_TomPlanarMipCount<2 && major>.5)return probe;
    uv=saturate(uv);
    bool ranged=_TomPlanarRange.x>0 || _TomPlanarRange.y>0;
    if(major<=.5 || _TomPlanarParams.w==0){
        [branch] if(ranged){
            float w=TomPlanarHitAcceptance(uv);
            return TomPlanarRangeColor(_TomPlanarColor.SampleLevel(tom_sh_linear_clamp_sampler,uv,0),w,probe);
        }
        return _TomPlanarColor.SampleLevel(tom_sh_linear_clamp_sampler,uv,0).rgb;
    }
    float t=saturate((major/max(.001,minor)-1)*.5), center=.48+.07*t, blur=minor*(.5+.10*t);
    float2 radius=sqrt(max(0,2*(.5059*float2(major*major,minor*minor)-blur*blur)/(1-center)));
    float span=max(1,sqrt((blur*blur+.25)*2.4)), lod=min(floor(log2(span)),_TomPlanarMipCount-1);
    float ratio=span*exp2(-lod), fraction=saturate((ratio*ratio-1)/3);
    float3 sum=0;
    int k=_TomPlanarParams.w>1.5?8:4;
    [loop] for(int i=0;i<=k;i++){
        float a=.3926990817+6.28318530718*((i-1)/(float)k);
        float2 v; sincos(a,v.y,v.x);
        float2 offset=(axis*(v.x*radius.x)+float2(-axis.y,axis.x)*(v.y*radius.y));
        // Extend the last captured texel, not the probe, across the filter footprint.
        float2 q=saturate(uv+(i==0?float2(0,0):offset)*_TomPlanarTexelSize.xy);
        float ok=TomPlanarConfidence(q,hit,surf,range);
        float3 c=probe;
        [branch] if(ok>0){
            float4 lo=_TomPlanarColor.SampleLevel(tom_sh_linear_clamp_sampler,q,lod);
            float4 hi=_TomPlanarColor.SampleLevel(tom_sh_linear_clamp_sampler,q,min(lod+1,_TomPlanarMipCount-1));
            float4 v=lerp(lo,hi,fraction);
            [branch] if(ranged){
                float w=TomPlanarHitAcceptance(q);
                c=lerp(probe,TomPlanarRangeColor(v,w,probe),ok);
            }else c=lerp(probe,v.rgb,ok);
        }
        sum+=c*(i==0?center:(1-center)/k);
    }
    return sum;
}
#endif
