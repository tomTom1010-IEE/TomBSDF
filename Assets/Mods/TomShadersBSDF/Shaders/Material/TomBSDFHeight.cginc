#ifndef TOM_BSDF_HEIGHT_INCLUDED
#define TOM_BSDF_HEIGHT_INCLUDED

UNITY_DECLARE_TEX2D(_HeightMap);
float4 _HeightMap_ST, _HeightMap_TexelSize;
float _HeightScale, _IsHeightReverse, _ParallaxMode, _ParallaxQuality;
float _ParallaxFadeStart, _ParallaxFadeEnd, _ParallaxGrazingFade, _ParallaxMaxOffset;
float _ParallaxSelfShadow, _ParallaxSelfShadowStrength, _ParallaxSelfShadowBias;

// Height-v1: linear R, white at the mesh envelope, black HeightScale meters below.
// This decoder is shared with future geometry displacement, not glass thickness.
float TomDecodeHeight(float value)
{
    float h = saturate(TomDataInput(value.xxx, _DataTextureRestore).r);
    return _IsHeightReverse > 0.5 ? 1.0 - h : h;
}

float TomReadHeight(float2 uv, float2 dx, float2 dy)
{
    return TomDecodeHeight(_HeightMap.SampleGrad(sampler_HeightMap,
        TomUV(uv, _HeightMap_ST), dx * _HeightMap_ST.xy, dy * _HeightMap_ST.xy).r);
}
#endif
