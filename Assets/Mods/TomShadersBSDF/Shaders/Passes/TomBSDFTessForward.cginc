#include "TomBSDFForward.cginc"
#include "../Platform/Unity2019/TomBSDFTessellation.cginc"

[domain("tri")]
TomVertexOutput TomBSDFTessDomain(TomTessFactors factors,
    const OutputPatch<TomTessControlPoint, 3> patch, float3 bary : SV_DomainLocation)
{
    TomTessInput displaced = TomBSDFDisplacedVertex(patch, bary);
    TomVertexInput v;
    v.vertex = displaced.vertex;
    v.normal = displaced.normal;
    v.tangent = displaced.tangent;
    v.uv = displaced.uv;
    TomVertexOutput o = TomBSDFVertex(v);
    o.fallbackLights = patch[0].fallbackLights;
    return o;
}
