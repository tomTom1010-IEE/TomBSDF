#include "TomBSDFShadow.cginc"
#include "../Platform/Unity2019/TomBSDFTessellation.cginc"

// Built-in Forward also uses this caster for _CameraDepthTexture. Do not
// insert a non-tessellated depth fallback or an unrelated DepthOnly pass.
[domain("tri")]
TomShadowOutput TomBSDFTessShadowDomain(TomTessFactors factors,
    const OutputPatch<TomTessControlPoint, 3> patch, float3 bary : SV_DomainLocation)
{
    TomTessInput displaced = TomBSDFDisplacedVertex(patch, bary);
    appdata_base v;
    UNITY_INITIALIZE_OUTPUT(appdata_base, v);
    v.vertex = displaced.vertex;
    v.normal = displaced.normal;
    v.texcoord = float4(displaced.uv, 0, 0);
    return TomBSDFShadowVertex(v);
}
