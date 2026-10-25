#ifndef TOM_BSDF_GLASS_REFRACTION_INCLUDED
#define TOM_BSDF_GLASS_REFRACTION_INCLUDED
#include "TomBSDFSceneBuffers.cginc"

struct TomGlassScreenHit
{
    float2 uv;
    float eyeDepth, weight;
};

bool TomGlassProject(float3 position, out float2 uv)
{
    float4 clipPosition = mul(UNITY_MATRIX_VP, float4(position, 1.0));
    float4 screen = ComputeScreenPos(clipPosition);
    uv = screen.xy / max(screen.w, 1e-6);
    float2 margin = _TomBSDFBufferSize.zw * 0.5;
    return clipPosition.w > 0.0 && all(uv >= margin) && all(uv <= 1.0 - margin);
}

TomGlassScreenHit TomGlassFindBackground(TomGlassSurface s)
{
    TomGlassScreenHit hit = (TomGlassScreenHit)0;
    if (_UseSceneRefraction < 0.5 || _IOR <= 1.00001
        || !TomSceneBuffersAvailable(TOM_SCENE_BUFFER_COLOR | TOM_SCENE_BUFFER_DEPTH)) return hit;
    float2 uv;
    if (!TomGlassProject(s.geometry.position, uv)) return hit;
    float depth;
    if (!TomTrySceneEyeDepth(uv, depth)) return hit;
    float entryDepth = -mul(UNITY_MATRIX_V, float4(s.geometry.position, 1.0)).z;
    float exitDepth = -mul(UNITY_MATRIX_V, float4(s.transport.exitPosition, 1.0)).z;
    float3 outgoing = -s.geometry.view; // Parallel slab: exit direction equals incident direction.
    float dz = -mul((float3x3)UNITY_MATRIX_V, outgoing).z;
    if (dz <= 1e-5) return hit;
    float bias = max(_GlassDepthBias, 1e-5);
    // Two bounded depth-plane refinements, not SSR or hidden-surface tracing.
    [unroll] for (int stepIndex = 0; stepIndex < 2; stepIndex++)
    {
        if (depth <= max(entryDepth, exitDepth) + bias) return hit;
        float3 candidate = s.transport.exitPosition + outgoing * ((depth - exitDepth) / dz);
        if (!TomGlassProject(candidate, uv)) return hit;
        float nextDepth;
        if (!TomTrySceneEyeDepth(uv, nextDepth)) return hit;
        if (nextDepth <= max(entryDepth, exitDepth) + bias) return hit;
        depth = nextDepth;
    }
    float3 finalPosition = s.transport.exitPosition + outgoing * ((depth - exitDepth) / dz);
    if (!TomGlassProject(finalPosition, uv)) return hit;
    float finalDepth;
    if (!TomTrySceneEyeDepth(uv, finalDepth) || finalDepth <= max(entryDepth, exitDepth) + bias) return hit;
    // A discontinuous depth-plane iteration has not found a reliable background.
    if (abs(finalDepth - depth) > max(bias * 4.0, depth * 0.01)) return hit;
    float2 edge = min(uv, 1.0 - uv);
    hit.weight = saturate(min(edge.x, edge.y) / max(_GlassEdgeFade, 1e-5));
    hit.uv = uv; hit.eyeDepth = finalDepth;
    return hit;
}

float3 TomGlassBackgroundColor(TomGlassSurface s, TomGlassScreenHit hit)
{
    float3 center;
    if (hit.weight <= 0.0 || !TomTrySceneColor(hit.uv, center)) return 0.0;
    float2 axes = TomAnisotropicAxes(s.material.roughness, s.material.anisotropy);
    float etaSpread = abs(_IOR - 1.0) / max(_IOR, 1.0);
    if (max(axes.x, axes.y) * etaSpread < 1e-5) return center;
    float entryDepth = -mul(UNITY_MATRIX_V, float4(s.geometry.position, 1.0)).z;
    float distanceToBackground = max(hit.eyeDepth - entryDepth, 0.0);
    float3 p = s.transport.exitPosition - s.geometry.view * distanceToBackground;
    float2 pUV, uUV, vUV;
    if (!TomGlassProject(p, pUV)
        || !TomGlassProject(p + s.geometry.tangent * (axes.x * etaSpread * distanceToBackground), uUV)
        || !TomGlassProject(p + s.geometry.bitangent * (axes.y * etaSpread * distanceToBackground), vUV)) return center;
    float2 u = uUV - pUV, v = vUV - pUV;
    float3 result = center * 4.0;
    [unroll] for (int tap = 0; tap < 8; tap++)
    {
        float angle = (tap + 0.5) * (TOM_BSDF_PI / 4.0);
        float2 uv = hit.uv + (cos(angle) * u + sin(angle) * v) * 0.75;
        float depth; float3 value;
        bool valid = TomTrySceneEyeDepth(uv, depth);
        valid = valid && depth > entryDepth + max(_GlassDepthBias, 1e-5)
            && abs(depth - hit.eyeDepth) < max(_GlassDepthBias * 4.0, hit.eyeDepth * 0.1);
        if (valid && TomTrySceneColor(uv, value)) result += value;
        else result += center;
    }
    // Positive normalized nine-tap elliptical filter. This is deliberately not
    // advertised as exact rough GGX BTDF integration or a depth-complete scene.
    return result / 12.0;
}
#endif
