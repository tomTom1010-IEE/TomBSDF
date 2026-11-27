#ifndef TOM_NATIVE_REFLECTION_ACCEPTANCE
#define TOM_NATIVE_REFLECTION_ACCEPTANCE
float4 _TomEnvBinding, _TomEnvSkyDecode;
TextureCube<float4> _TomEnvSky;
float3 TomNativeAcceptance(TomBSDFMaterial m,TomBSDFGeometry g,float3 native,float pw,float sw) {
    if(pw<=0 && sw<=0)return 0;
    if((pw>=1 && sw>=1) || _TomEnvBinding.y<.5)return native;
    float share=saturate(_TomEnvBinding.x);
    pw=saturate(pw);sw=saturate(sw);
    if(share<=0)return native*sw;
    float mip=m.roughness*(1.7-.7*m.roughness)*UNITY_SPECCUBE_LOD_STEPS;
    float3 sky=TomColorInput(TomDecodeProbeHDR(_TomEnvSky.SampleLevel(tom_sh_linear_clamp_sampler,
        TomSpecularReflection(m,g),mip),_TomEnvSkyDecode),_ReflectionColorMode);
    return max(0,native*pw+sky*((1-share*pw)*sw-(1-share)*pw));
}
#endif
