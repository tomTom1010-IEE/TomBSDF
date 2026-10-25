#ifndef TOM_BSDF_PARALLAX_INCLUDED
#define TOM_BSDF_PARALLAX_INCLUDED

struct TomHeightContext
{
    float2 uv, dx, dy;
    float3 normal, dualU, dualV, position;
    float scale, depth, fade;
};

// The material adapter supplies TomReadHeight; all ray math uses raw UV0 and meters.
float TomParallaxIntersection(float2 uv, float2 offset, float2 dx, float2 dy, int steps, int refinements)
{
    float lower = 0.0;
    float lowerValue = TomReadHeight(uv, dx, dy) - 1.0;
    if (lowerValue >= 0.0) return 0.0;
    float upper = 1.0;
    float upperValue = 0.0;
    [loop] for (int j = 1; j <= steps; ++j)
    {
        float t = (float)j / (float)steps;
        float value = t + TomReadHeight(uv + offset * t, dx, dy) - 1.0;
        if (value >= 0.0)
        {
            upper = t;
            upperValue = value;
            break;
        }
        lower = t;
        lowerValue = value;
    }
    float hit = lower;
    [loop] for (int k = 0; k < refinements; ++k)
    {
        hit = lerp(lower, upper, saturate(-lowerValue / max(upperValue - lowerValue, 1e-7)));
        float value = hit + TomReadHeight(uv + offset * hit, dx, dy) - 1.0;
        if (value >= 0.0) { upper = hit; upperValue = value; }
        else { lower = hit; lowerValue = value; }
    }
    return lerp(lower, upper, saturate(-lowerValue / max(upperValue - lowerValue, 1e-7)));
}

TomSurfaceCoordinates TomParallaxCoordinates(TomSurfaceCoordinates c, float3 position,
    float3 smoothNormal, float3 view, float3 positionDx, float3 positionDy, out TomHeightContext height)
{
    height = (TomHeightContext)0;
    [branch] if (_ParallaxMode < 0.5 || _HeightScale <= 0.0) return c;
    c.explicitGrad = 1.0;
    float determinant = c.dx.x * c.dy.y - c.dx.y * c.dy.x;
    if (abs(determinant) < 1e-16) return c;
    float3 n = TomSafeNormalize(smoothNormal);
    n *= dot(n, view) < 0.0 ? -1.0 : 1.0;
    float noV = saturate(dot(n, view));
    float3 du = (positionDx * c.dy.y - positionDy * c.dx.y) / determinant;
    float3 dv = (positionDy * c.dx.x - positionDx * c.dy.x) / determinant;
    du -= n * dot(n, du);
    dv -= n * dot(n, dv);
    float uu = dot(du, du), uv = dot(du, dv), vv = dot(dv, dv);
    float gram = uu * vv - uv * uv;
    if (gram <= max(uu * vv * 1e-8, 1e-20)) return c;

    float3 tangentStep = n - view / max(noV, 1e-4);
    float2 q = float2(dot(tangentStep, du), dot(tangentStep, dv));
    float2 offset = float2(vv * q.x - uv * q.y, uu * q.y - uv * q.x) / gram;
    float distanceToEye = length(_WorldSpaceCameraPos.xyz - position);
    float distanceFade = 1.0 - smoothstep(max(_ParallaxFadeStart, 0.0),
        max(_ParallaxFadeEnd, _ParallaxFadeStart + 0.001), distanceToEye);
    float angleFade = smoothstep(0.0, max(_ParallaxGrazingFade, 0.001), noV);
    float2 texels = _HeightMap_TexelSize.zw * abs(_HeightMap_ST.xy);
    float lod = log2(max(max(length(c.dx * texels), length(c.dy * texels)), 1.0));
    float lastMip = log2(max(max(_HeightMap_TexelSize.z, _HeightMap_TexelSize.w), 4.0));
    float mipFade = 1.0 - smoothstep(max(lastMip - 3.0, 0.0), max(lastMip - 1.0, 1.0), lod);
    float scale = max(_HeightScale, 0.0) * distanceFade * angleFade * mipFade;
    offset *= scale;
    float excursion = length(offset * _HeightMap_ST.xy);
    float limit = min(1.0, max(_ParallaxMaxOffset, 0.001) / max(excursion, 1e-8));
    offset *= limit;
    scale *= limit;
    if (scale <= 0.0) return c;

    int maxSteps = _ParallaxQuality < 0.5 ? 32 : 96;
    int minSteps = _ParallaxQuality < 0.5 ? 12 : 32;
    int steps = (int)ceil(lerp((float)minSteps, (float)maxSteps, 1.0 - noV));
    float hit = TomParallaxIntersection(c.uv, offset, c.dx, c.dy, steps, _ParallaxQuality < 0.5 ? 2 : 5);
    c.uv += offset * hit;
    c.depth = hit * scale;
    [branch] if (_ParallaxSelfShadow > 0.5 && _ParallaxSelfShadowStrength > 0.0)
    {
        height.uv = c.uv;
        height.dx = c.dx;
        height.dy = c.dy;
        height.normal = n;
        height.dualU = (vv * du - uv * dv) / gram;
        height.dualV = (uu * dv - uv * du) / gram;
        height.position = position - view * (c.depth / max(noV, 1e-4));
        height.scale = scale;
        height.depth = c.depth;
        height.fade = distanceFade * angleFade * mipFade * limit;
    }
    return c;
}

TomSurfaceCoordinates TomParallaxCoordinates(TomSurfaceCoordinates c, float3 position,
    float3 smoothNormal, float3 view, float3 positionDx, float3 positionDy)
{
    TomHeightContext unused;
    return TomParallaxCoordinates(c, position, smoothNormal, view, positionDx, positionDy, unused);
}

// A height-field visibility query, not a BRDF or a replacement native shadow map.
// source.w=0 is a direction toward the light; source.w=1 is a finite light position.
float TomParallaxVisibility(TomHeightContext height, float4 source)
{
    [branch] if (_ParallaxSelfShadow < 0.5 || _ParallaxSelfShadowStrength <= 0.0 ||
        height.scale <= 0.0 || height.depth <= height.scale * 1e-5) return 1.0;
    float3 delta = source.xyz - height.position * source.w;
    float distanceSquared = dot(delta, delta);
    if (distanceSquared <= 1e-12) return 1.0;
    float distanceToLight = sqrt(distanceSquared);
    float3 direction = delta / distanceToLight;
    float noL = dot(height.normal, direction);
    // The local planar model is unreliable at its horizon. Fail open, rather
    // than inventing geometry or blackening an independently normal-mapped coat.
    float lightFade = smoothstep(0.02, 0.08, noL);
    if (lightFade <= 0.0) return 1.0;
    float travel = height.depth / max(noL, 1e-4);
    if (source.w > 0.5) travel = min(travel, distanceToLight);
    float2 rate = float2(dot(height.dualU, direction), dot(height.dualV, direction));
    float excursion = length(rate * travel * _HeightMap_ST.xy);
    // Bounded local neighborhood: do not silently rescale geometry for each lamp.
    float rangeFade = 1.0 - smoothstep(1.0, 2.0, excursion);
    if (rangeFade <= 0.0) return 1.0;
    float footprint = max(length(height.dx * _HeightMap_ST.xy), length(height.dy * _HeightMap_ST.xy));
    float filterWidth = height.scale * (1.0 / 4096.0 + min(footprint, 0.05) * 0.25);
    float bias = height.scale * (1.0 / 2048.0 + min(footprint, 0.05) * 0.25)
        * max(_ParallaxSelfShadowBias, 0.0);
    int steps = (int)ceil(lerp(_ParallaxQuality < 0.5 ? 8.0 : 24.0,
        _ParallaxQuality < 0.5 ? 16.0 : 48.0, 1.0 - saturate(noL)));
    float blocked = 0.0;
    [loop] for (int j = 1; j <= steps; ++j)
    {
        float t = travel * ((float)j / (float)steps);
        float surfaceDepth = (1.0 - TomReadHeight(height.uv + rate * t, height.dx, height.dy)) * height.scale;
        float rayDepth = height.depth - noL * t;
        blocked = max(blocked, smoothstep(bias, bias + filterWidth, rayDepth - surfaceDepth));
        if (blocked >= 1.0) break;
    }
    return 1.0 - saturate(_ParallaxSelfShadowStrength) * height.fade * lightFade * rangeFade * blocked;
}

float2 TomParallaxFootprint(float2 shifted, float2 original)
{
    // Finite hit differences include perspective compression. Bound disocclusion
    // jumps to a conservative 16x footprint; this is not an exact ray differential.
    float lengthSquared = dot(shifted, shifted);
    float maximum = max(dot(original, original) * 256.0, 1e-16);
    return shifted * sqrt(min(1.0, maximum / max(lengthSquared, 1e-20)));
}
#endif
