#ifndef TOM_BSDF_TESSELLATION_INCLUDED
#define TOM_BSDF_TESSELLATION_INCLUDED

UNITY_DECLARE_TEX2D(_DisplacementMask);
float4 _DisplacementMask_ST, _DisplacementMask_TexelSize;
float _TessellationMode, _TessFactor, _TessEdgeLength, _TessMaxFactor;
float _DisplacementMip, _DisplacementEdgeFade;

struct TomTessInput
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
};

struct TomTessControlPoint
{
    float4 vertex : INTERNALTESSPOS;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
    float fallbackLights : TEXCOORD1;
};

struct TomTessFactors
{
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

float3 TomTessNormalize(float3 n)
{
    return n * rsqrt(max(dot(n, n), 1e-20));
}

TomTessControlPoint TomBSDFTessVertex(TomTessInput v)
{
    TomTessControlPoint o;
    o.vertex = v.vertex;
    o.normal = v.normal;
    o.tangent = v.tangent;
    o.uv = v.uv;
    // VERTEXLIGHT_ON is a vertex-stage keyword in Unity's fwdbase variants.
    // Carry it through HS/DS; do not re-evaluate it in the domain program.
    #if defined(VERTEXLIGHT_ON) && defined(UNITY_PASS_FORWARDBASE)
        o.fallbackLights = 1.0;
    #else
        o.fallbackLights = 0.0;
    #endif
    return o;
}

float TomTessEdgeFactor(float3 a, float3 b)
{
    if (_HeightScale <= 0.0) return 1.0;
    float maximum = clamp(_TessMaxFactor, 1.0, 63.0);
    float factor = _TessellationMode < 0.5 ? _TessFactor
        : length(mul((float3x3)unity_ObjectToWorld, b - a)) / max(_TessEdgeLength, 0.001);
    return clamp(factor, 1.0, maximum);
}

TomTessFactors TomBSDFTessPatch(InputPatch<TomTessControlPoint, 3> patch)
{
    TomTessFactors f;
    // Symmetric endpoint-only rule: neither the camera/light nor the third
    // vertex can change a shared edge's subdivision in any pass.
    f.edge[0] = TomTessEdgeFactor(patch[1].vertex.xyz, patch[2].vertex.xyz);
    f.edge[1] = TomTessEdgeFactor(patch[2].vertex.xyz, patch[0].vertex.xyz);
    f.edge[2] = TomTessEdgeFactor(patch[0].vertex.xyz, patch[1].vertex.xyz);
    f.inside = max(f.edge[0], max(f.edge[1], f.edge[2]));
    return f;
}

[domain("tri")]
[partitioning("fractional_odd")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(3)]
[patchconstantfunc("TomBSDFTessPatch")]
[maxtessfactor(63.0)]
TomTessControlPoint TomBSDFTessHull(InputPatch<TomTessControlPoint, 3> patch,
    uint id : SV_OutputControlPointID)
{
    return patch[id];
}

float TomTessMip(float4 texelSize)
{
    return clamp(_DisplacementMip, 0.0, log2(max(max(texelSize.z, texelSize.w), 1.0)));
}

// Explicit uniform mip is camera/pass independent. Derivatives include the
// map's own ST and decoded data/reversal, not RGB normal-map conventions.
float3 TomTessHeightSample(float2 uv)
{
    float lod = TomTessMip(_HeightMap_TexelSize);
    float2 step = max(abs(_HeightMap_TexelSize.xy) * exp2(lod), 1e-7);
    float2 p = TomUV(uv, _HeightMap_ST);
    float center = TomDecodeHeight(_HeightMap.SampleLevel(sampler_HeightMap, p, lod).r);
    float x0 = TomDecodeHeight(_HeightMap.SampleLevel(sampler_HeightMap, p - float2(step.x, 0), lod).r);
    float x1 = TomDecodeHeight(_HeightMap.SampleLevel(sampler_HeightMap, p + float2(step.x, 0), lod).r);
    float y0 = TomDecodeHeight(_HeightMap.SampleLevel(sampler_HeightMap, p - float2(0, step.y), lod).r);
    float y1 = TomDecodeHeight(_HeightMap.SampleLevel(sampler_HeightMap, p + float2(0, step.y), lod).r);
    return float3(center, (x1 - x0) * _HeightMap_ST.x / (2.0 * step.x),
        (y1 - y0) * _HeightMap_ST.y / (2.0 * step.y));
}

float TomTessMask(float2 p, float lod)
{
    return saturate(TomDataInput(_DisplacementMask.SampleLevel(sampler_DisplacementMask, p, lod).rrr,
        _DataTextureRestore).r);
}

float3 TomTessMaskSample(float2 uv)
{
    float lod = TomTessMip(_DisplacementMask_TexelSize);
    float2 step = max(abs(_DisplacementMask_TexelSize.xy) * exp2(lod), 1e-7);
    float2 p = TomUV(uv, _DisplacementMask_ST);
    float center = TomTessMask(p, lod);
    float x = (TomTessMask(p + float2(step.x, 0), lod) - TomTessMask(p - float2(step.x, 0), lod))
        * _DisplacementMask_ST.x / (2.0 * step.x);
    float y = (TomTessMask(p + float2(0, step.y), lod) - TomTessMask(p - float2(0, step.y), lod))
        * _DisplacementMask_ST.y / (2.0 * step.y);
    return float3(center, x, y);
}

float3 TomTessEdgeFade(float3 bary)
{
    if (_DisplacementEdgeFade <= 0.0) return float3(1, 0, 0);
    float nearest = bary.x;
    float2 derivative = float2(-1, -1);
    if (bary.y < nearest) { nearest = bary.y; derivative = float2(1, 0); }
    if (bary.z < nearest) { nearest = bary.z; derivative = float2(0, 1); }
    float width = max(_DisplacementEdgeFade, 1e-5);
    float t = saturate(nearest / width);
    return float3(t * t * (3.0 - 2.0 * t), derivative * (6.0 * t * (1.0 - t) / width));
}

TomTessInput TomBSDFDisplacedVertex(const OutputPatch<TomTessControlPoint, 3> patch, float3 bary)
{
    TomTessInput v;
    v.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
    v.normal = patch[0].normal * bary.x + patch[1].normal * bary.y + patch[2].normal * bary.z;
    v.tangent = patch[0].tangent * bary.x + patch[1].tangent * bary.y + patch[2].tangent * bary.z;
    v.uv = patch[0].uv * bary.x + patch[1].uv * bary.y + patch[2].uv * bary.z;
    [branch] if (_HeightScale <= 0.0) return v;

    float3 height = TomTessHeightSample(v.uv);
    float3 mask = TomTessMaskSample(v.uv);
    float3 fade = TomTessEdgeFade(bary);
    float scale = clamp(_HeightScale, 0.0, 0.2);
    float offset = (height.x - 1.0) * scale * mask.x * fade.x;
    float2 gradient = scale * (height.yz * mask.x + (height.x - 1.0) * mask.yz) * fade.x;
    float2 uv1 = patch[1].uv - patch[0].uv, uv2 = patch[2].uv - patch[0].uv;
    float2 derivative = float2(dot(gradient, uv1), dot(gradient, uv2))
        + (height.x - 1.0) * scale * mask.x * fade.yz;

    // White envelope / black displacement mask returns the original frame too.
    if (abs(offset) + dot(abs(derivative), float2(1, 1)) <= 1e-12) return v;
    float3 nRaw = mul(v.normal, (float3x3)unity_WorldToObject);
    float nLength = sqrt(max(dot(nRaw, nRaw), 1e-20));
    float3 n = nRaw / nLength;
    float3 nd1 = mul(patch[1].normal - patch[0].normal, (float3x3)unity_WorldToObject);
    float3 nd2 = mul(patch[2].normal - patch[0].normal, (float3x3)unity_WorldToObject);
    nd1 = (nd1 - n * dot(n, nd1)) / nLength;
    nd2 = (nd2 - n * dot(n, nd2)) / nLength;
    float3 e1 = mul((float3x3)unity_ObjectToWorld, patch[1].vertex.xyz - patch[0].vertex.xyz) + offset * nd1;
    float3 e2 = mul((float3x3)unity_ObjectToWorld, patch[2].vertex.xyz - patch[0].vertex.xyz) + offset * nd2;
    float3 q1 = e1 - n * dot(e1, n), q2 = e2 - n * dot(e2, n);
    float aa = dot(q1, q1), ab = dot(q1, q2), bb = dot(q2, q2);
    float gram = aa * bb - ab * ab;
    float3 displacedNormal = n;
    if (gram > max(aa * bb * 1e-8, 1e-20))
        displacedNormal = TomTessNormalize(n - ((bb * q1 - ab * q2) * derivative.x
            + (aa * q2 - ab * q1) * derivative.y) / gram);

    float3 position = mul(unity_ObjectToWorld, v.vertex).xyz + n * offset;
    v.vertex = mul(unity_WorldToObject, float4(position, 1.0));
    v.normal = mul(displacedNormal, (float3x3)unity_ObjectToWorld);
    float3 tangent = mul((float3x3)unity_ObjectToWorld, v.tangent.xyz);
    float handedness = v.tangent.w * unity_WorldTransformParams.w;
    float determinant = uv1.x * uv2.y - uv1.y * uv2.x;
    if (abs(determinant) > 1e-12)
    {
        float3 dp1 = e1 + n * derivative.x, dp2 = e2 + n * derivative.y;
        tangent = (dp1 * uv2.y - dp2 * uv1.y) / determinant;
        float3 bitangent = (dp2 * uv1.x - dp1 * uv2.x) / determinant;
        handedness = dot(cross(displacedNormal, tangent), bitangent) < 0.0 ? -1.0 : 1.0;
    }
    tangent -= displacedNormal * dot(displacedNormal, tangent);
    if (dot(tangent, tangent) < 1e-12)
        tangent = cross(abs(displacedNormal.z) < 0.999 ? float3(0, 0, 1) : float3(0, 1, 0), displacedNormal);
    v.tangent = float4(mul((float3x3)unity_WorldToObject, TomTessNormalize(tangent)),
        (handedness < 0.0 ? -1.0 : 1.0) * unity_WorldTransformParams.w);
    return v;
}
#endif
