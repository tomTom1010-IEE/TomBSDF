#ifndef TOM_SCREEN_RECEIVER_INCLUDED
#define TOM_SCREEN_RECEIVER_INCLUDED
// Explicitly drawn receiver pass only. The native depth source is copied at
// AfterForwardOpaque; replacement shaders and planar/probe cameras are ineligible.
Texture2D<float> _TomSSRSourceDepth;
float _ReflectionsEnabled, _SSRWeight, _SSRBaseWeight, _SSRCoatWeight;
#if !defined(TOM_SCREEN_RESOLVE)
    Texture2D<float4> _PlanarReflectionMask;
    float4 _PlanarReflectionMask_ST;
#endif
struct TomSSRFrames { float4 substrate:SV_Target0; float4 coat:SV_Target1; };

void TomSSRVisible(TomVertexOutput i) {
    float raw=_TomSSRSourceDepth.Load(int3((int2)i.pos.xy,0));
    // Both the Copy and SV_Position are D3D device Z in source pixel space.
    // No rear receiver through a foreground wall. Only tolerate raster roundoff.
    clip(1e-6-abs(raw-i.pos.z));
}
void TomSSRSurface(TomVertexOutput i,float front,out TomSurfaceCoordinates c,
    out TomBSDFMaterial intrinsic,out TomBSDFMaterial base,out TomBSDFGeometry g,
    out TomBSDFGeometry frame,out float nv,out float rv) {
    TomClipCoverage(TomCoverage(i.uv));
    c=TomUnshiftedCoordinates(i.uv);
    #if defined(TOM_BSDF_PARALLAX)
        c.dx=ddx(i.uv);c.dy=ddy(i.uv);
        float3 v=TomSafeNormalize(lerp(UnityWorldSpaceViewDir(i.position),UNITY_MATRIX_V[2].xyz,unity_OrthoParams.w));
        TomHeightContext hc;
        c=TomParallaxCoordinates(c,i.position,i.normal,v,ddx(i.position),ddy(i.position),hc);
        float2 sx=ddx(c.uv),sy=ddy(c.uv);
        if(c.explicitGrad>.5){c.dx=TomParallaxFootprint(sx,c.dx);c.dy=TomParallaxFootprint(sy,c.dy);}
    #endif
    intrinsic=TomReadMaterial(c);base=intrinsic;
    g=TomReadGeometry(i.position,i.normal,i.tangent,c,front>0?1:-1);frame=g;
    if(base.anisotropy>0) TomRotateAnisotropicFrame(g,base.anisotropyRotation);
    float3 nx=ddx(g.normal),ny=ddy(g.normal);
    float rx=dot(g.bitangent,ddx(g.tangent)),ry=dot(g.bitangent,ddy(g.tangent));
    nv=dot(nx,nx)+dot(ny,ny);rv=rx*rx+ry*ry;
    if(_SpecularAAStrength>0) {
        if(base.anisotropy>0)TomFilterAnisotropicRoughness(base,nv,rv,_SpecularAAStrength,_SpecularAAVariance,_SpecularAAThreshold);
        else base.roughness=TomFilterSpecularRoughness(base.roughness,nx,ny,_SpecularAAStrength,_SpecularAAVariance,_SpecularAAThreshold);
    }
}
float4 TomSSRFrame(TomBSDFMaterial m,TomBSDFGeometry g) {
    float3 h=g.view+TomSpecularReflection(m,g);
    return float4(mul((float3x3)UNITY_MATRIX_V,TomSafeNormalize(h)),m.roughness);
}
TomSSRFrames TomSSRReceiver(TomVertexOutput i,float front:VFACE) {
    TomSSRVisible(i);
    TomSSRFrames o=(TomSSRFrames)0;
    if(_ReflectionsEnabled<.5 || _SSRWeight<=0 || _ReflectionIntensity<=0 || _DebugView>.5)return o;
    TomSurfaceCoordinates c;TomBSDFMaterial intrinsic,m;TomBSDFGeometry g,f;float nv,rv;
    TomSSRSurface(i,front,c,intrinsic,m,g,f,nv,rv);
    float mask=TomSampleSurfaceData(_PlanarReflectionMask,tom_sh_linear_clamp_sampler,_PlanarReflectionMask_ST,c).g;
    if(mask<=0)return o;
    if(_SSRBaseWeight>0)o.substrate=TomSSRFrame(m,g);
    if(_CoatWeight>0 && _SSRCoatWeight>0) {
        TomBSDFLayers s=TomReadLayers(c,intrinsic,g,f,nv,rv);
        if(s.weight>0)o.coat=TomSSRFrame(s.coat,s.coatGeometry);
    }
    return o;
}
#endif
