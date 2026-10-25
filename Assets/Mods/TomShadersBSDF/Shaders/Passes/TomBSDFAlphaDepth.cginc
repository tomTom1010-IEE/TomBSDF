#include "UnityCG.cginc"
#include "../Material/TomBSDFInputs.cginc"

// Keep depth-only culling out of the shared Forward compiler input.
float _AlphaDepthMode, _AlphaDepthCutoff;
#if !defined(TOM_BSDF_ALPHA_BACKFRONT)
    float _CullOption;
#endif

void TomAlphaClipDepth(float coverage, float facing)
{
    TomClipCoverage(coverage);
    clip(_AlphaDepthMode - 0.5);
    clip(coverage - max(_AlphaDepthCutoff, 1e-6));
    if (_AlphaDepthMode > 1.5) clip(-facing);
    #if !defined(TOM_BSDF_ALPHA_BACKFRONT)
    else
    {
        if (_CullOption > 1.5) clip(facing);
        else if (_CullOption > 0.5) clip(-facing);
    }
    #endif
}

struct TomAlphaDepthOutput
{
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
};

TomAlphaDepthOutput TomBSDFAlphaDepthVertex(appdata_base v)
{
    TomAlphaDepthOutput o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;
    return o;
}

float4 TomBSDFAlphaDepthFragment(TomAlphaDepthOutput i, float facing : VFACE) : SV_Target
{
    TomAlphaClipDepth(TomCoverage(i.uv), facing);
    return 0.0;
}
