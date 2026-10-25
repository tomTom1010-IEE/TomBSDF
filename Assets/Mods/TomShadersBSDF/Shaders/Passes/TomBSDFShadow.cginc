#include "UnityCG.cginc"
#include "../Material/TomBSDFInputs.cginc"

#if defined(TOM_BSDF_ALPHA)
float _AlphaShadowMode, _AlphaShadowCutoff;

// Fixed 4x4 ordered coverage in shadow-map raster space. This approximates
// fractional visibility, not colored transmission or a physical glass shadow.
float TomAlphaShadowThreshold(float2 pixel)
{
    uint2 p = (uint2)floor(pixel) & 3;
    uint low = ((p.x ^ p.y) & 1) * 2 + (p.y & 1);
    uint high = (((p.x ^ p.y) >> 1) & 1) * 2 + ((p.y >> 1) & 1);
    return (low * 4 + high + 0.5) / 16.0;
}

void TomAlphaClipShadow(float coverage, float2 pixel)
{
    TomClipCoverage(coverage);
    clip(_AlphaShadowMode - 0.5);
    if (_AlphaShadowMode > 1.5) clip(coverage - TomAlphaShadowThreshold(pixel));
    else clip(coverage - max(_AlphaShadowCutoff, 1e-6));
}
#endif

struct TomShadowOutput
{
    V2F_SHADOW_CASTER;
    float2 uv : TEXCOORD1;
};

TomShadowOutput TomBSDFShadowVertex(appdata_base v)
{
    TomShadowOutput o;
    o.uv = v.texcoord;
    TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
    return o;
}

float4 TomBSDFShadowFragment(TomShadowOutput i) : SV_Target
{
    #if defined(TOM_BSDF_ALPHA)
        TomAlphaClipShadow(TomCoverage(i.uv), i.pos.xy);
    #else
        TomClipCoverage(TomCoverage(i.uv));
    #endif
    SHADOW_CASTER_FRAGMENT(i)
}
