// Only included in the authored, non-default ForwardBase variant. The normal
// variant retains the native source and pays no extra texture reads or branches.
float _ReflectionsEnabled, _ProbeWeight, _SkyWeight;
#include "TomNativeReflectionAcceptance.cginc"
float3 TomUnityProbeEnvironment(TomBSDFMaterial m,TomBSDFGeometry g) {
    if(_ReflectionsEnabled<.5 || (_ProbeWeight<=0 && _SkyWeight<=0))return 0;
    return TomNativeAcceptance(m,g,TomUnityUnmodifiedProbe(m,g),_ProbeWeight,_SkyWeight);
}
