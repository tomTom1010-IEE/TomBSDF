#ifndef TOM_BSDF_SCENE_BUFFERS_INCLUDED
#define TOM_BSDF_SCENE_BUFFERS_INCLUDED

// Optional consumer interface, deliberately not included in the opaque BRDF.
#define TOM_SCENE_BUFFER_COLOR 1
#define TOM_SCENE_BUFFER_DEPTH 2
#define TOM_SCENE_BUFFER_NORMALS_RESERVED 4
#define TOM_SCENE_BUFFER_SSR_RESERVED 8

Texture2D<float4> _TomBSDFSceneColor;
Texture2D<float> _TomBSDFSceneDepth;
#ifndef TOM_SCENE_COLOR_SAMPLER
SamplerState tom_scene_linear_clamp_sampler;
#define TOM_SCENE_COLOR_SAMPLER tom_scene_linear_clamp_sampler
#endif
float4 _TomBSDFBufferParams; // protocol, capability bits, camera ID, render sequence
float4 _TomBSDFBufferSize; // width, height, 1/width, 1/height
float4 _TomBSDFBufferProjection; // near, far, orthographic, reversed Z
float4x4 _TomBSDFBufferInverseProjection;
float4x4 _TomBSDFBufferCameraToWorld;

bool TomSceneBuffersAvailable(int capabilities)
{
    return abs(_TomBSDFBufferParams.x - 1.0) < 0.01 && _TomBSDFBufferParams.w > 0.0
        && (((int)_TomBSDFBufferParams.y & capabilities) == capabilities)
        && capabilities > 0 && (capabilities & ~3) == 0;
}

bool TomSceneBufferUVValid(float2 uv) { return all(uv >= 0.0) && all(uv <= 1.0); }

bool TomTrySceneColor(float2 screenUV, out float3 color)
{
    color = 0.0;
    if (!TomSceneBuffersAvailable(TOM_SCENE_BUFFER_COLOR) || !TomSceneBufferUVValid(screenUV)) return false;
    color = _TomBSDFSceneColor.Sample(TOM_SCENE_COLOR_SAMPLER, screenUV).rgb;
    return true;
}

bool TomTrySceneEyeDepth(float2 screenUV, out float eyeDepth)
{
    eyeDepth = 0.0;
    if (!TomSceneBuffersAvailable(TOM_SCENE_BUFFER_DEPTH) || !TomSceneBufferUVValid(screenUV)) return false;
    int2 pixel = min((int2)(screenUV * _TomBSDFBufferSize.xy), (int2)_TomBSDFBufferSize.xy - 1);
    float raw = _TomBSDFSceneDepth.Load(int3(pixel, 0));
    float forwardDepth = _TomBSDFBufferProjection.w > 0.5 ? 1.0 - raw : raw;
    float near = _TomBSDFBufferProjection.x, far = _TomBSDFBufferProjection.y;
    float denominator = _TomBSDFBufferProjection.w > 0.5 ? near + raw * (far - near) : far - raw * (far - near);
    eyeDepth = _TomBSDFBufferProjection.z > 0.5 ? lerp(near, far, forwardDepth)
        : near * far / max(denominator, 1e-7);
    return true;
}

// SSR is only a reserved capability bit. No tracing, filtering, allocation,
// material control or reflection contribution exists in this interface.
#endif
