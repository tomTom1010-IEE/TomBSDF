#ifndef TOM_BSDF_SHADOW_RECEIVER_ADAPTER_INCLUDED
#define TOM_BSDF_SHADOW_RECEIVER_ADAPTER_INCLUDED
// This include is compiled only for geometric coverage Alpha. No BRDF or
// screen-depth reconstruction belongs to the receiver resource adapter.
Texture2D<float4> _TomBSDFNativeShadowMetadata;
Texture2D<float> _TomBSDFNativeShadow0, _TomBSDFNativeShadow1, _TomBSDFNativeShadow2, _TomBSDFNativeShadow3;
Texture2D<float> _TomBSDFNativeShadow4, _TomBSDFNativeShadow5, _TomBSDFNativeShadow6, _TomBSDFNativeShadow7;
SamplerState tom_native_receiver_point_clamp_sampler;
float4 _TomBSDFNativeShadowParams;
float _TomBSDFReceiverOptOut;

float4 TomNativeShadowData(uint slot, uint field)
{
    return _TomBSDFNativeShadowMetadata.Load(int3(field, slot, 0));
}
float TomNativeShadowDepth(uint slot, float2 uv)
{
    [branch] if (slot == 0) return _TomBSDFNativeShadow0.SampleLevel(tom_native_receiver_point_clamp_sampler, uv, 0);
    [branch] if (slot == 1) return _TomBSDFNativeShadow1.SampleLevel(tom_native_receiver_point_clamp_sampler, uv, 0);
    [branch] if (slot == 2) return _TomBSDFNativeShadow2.SampleLevel(tom_native_receiver_point_clamp_sampler, uv, 0);
    [branch] if (slot == 3) return _TomBSDFNativeShadow3.SampleLevel(tom_native_receiver_point_clamp_sampler, uv, 0);
    [branch] if (slot == 4) return _TomBSDFNativeShadow4.SampleLevel(tom_native_receiver_point_clamp_sampler, uv, 0);
    [branch] if (slot == 5) return _TomBSDFNativeShadow5.SampleLevel(tom_native_receiver_point_clamp_sampler, uv, 0);
    [branch] if (slot == 6) return _TomBSDFNativeShadow6.SampleLevel(tom_native_receiver_point_clamp_sampler, uv, 0);
    return _TomBSDFNativeShadow7.SampleLevel(tom_native_receiver_point_clamp_sampler, uv, 0);
}
float TomNativeShadowCompare(uint slot, float2 uv, float depth)
{
    float stored = TomNativeShadowDepth(slot, uv);
    #if defined(UNITY_REVERSED_Z)
        return step(stored - 1e-6, depth);
    #else
        return step(depth, stored + 1e-6);
    #endif
}
float3 TomNativeShadowCoord(uint slot, uint cascade, float3 position)
{
    uint row = cascade * 4;
    float4 p = float4(position, 1);
    float4 projected = float4(dot(TomNativeShadowData(slot, row), p), dot(TomNativeShadowData(slot, row + 1), p),
        dot(TomNativeShadowData(slot, row + 2), p), dot(TomNativeShadowData(slot, row + 3), p));
    return projected.xyz / max(projected.w, 1e-8);
}
float2 TomNativeCubeUV(float3 v)
{
    float3 a = abs(v); float2 p; uint face;
    if (a.x >= a.y && a.x >= a.z) {
        face = v.x >= 0 ? 0 : 1; p = float2(v.x >= 0 ? -v.z : v.z, -v.y) / max(a.x, 1e-8);
    } else if (a.y >= a.z) {
        face = v.y >= 0 ? 2 : 3; p = float2(v.x, v.y >= 0 ? v.z : -v.z) / max(a.y, 1e-8);
    } else {
        face = v.z >= 0 ? 4 : 5; p = float2(v.z >= 0 ? v.x : -v.x, -v.y) / max(a.z, 1e-8);
    }
    return (p * .5 + .5 + float2(face % 3, face / 3)) / float2(3, 2);
}
float TomNativeShadowVisibility(uint slot, float3 position, uint type)
{
    float4 settings = TomNativeShadowData(slot, 30);
    float4 dimensions = TomNativeShadowData(slot, 26);
    float4 destination = TomNativeShadowData(slot, 33);
    if (any(dimensions.xy < 1)) return 1;
    float2 copiedSize = destination.xy / (type == 2 ? float2(3, 2) : float2(1, 1));
    if (any(dimensions.xy > copiedSize)) return 1;
    float visibility = 1;
    if (type == 2)
    {
        float3 delta = position - TomNativeShadowData(slot, 23).xyz;
        float4 projection = TomNativeShadowData(slot, 22);
        float dominant = max(abs(delta.x), max(abs(delta.y), abs(delta.z)));
        dominant = max(1e-5, dominant - projection.z) * projection.w;
        float depth = -projection.x + projection.y / max(dominant, 1e-5);
        #if defined(UNITY_REVERSED_Z)
            depth = 1 - depth;
        #endif
        if (settings.y < .5) visibility = TomNativeShadowCompare(slot, TomNativeCubeUV(delta), depth);
        else
        {
            // Unity's native point-light kernel crosses cube faces in direction
            // space; do not filter across unrelated adjacent atlas tiles.
            const float z = 1.0 / 128.0;
            visibility = .25 * (TomNativeShadowCompare(slot, TomNativeCubeUV(delta + float3(z,z,z)), depth)
                + TomNativeShadowCompare(slot, TomNativeCubeUV(delta + float3(-z,-z,z)), depth)
                + TomNativeShadowCompare(slot, TomNativeCubeUV(delta + float3(-z,z,-z)), depth)
                + TomNativeShadowCompare(slot, TomNativeCubeUV(delta + float3(z,-z,-z)), depth));
        }
    }
    else
    {
        uint cascade = 0;
        if (type == 0 && settings.x > 1.5)
        {
            cascade = 4;
            float4 radii = TomNativeShadowData(slot, 20);
            float4 splitsNear = TomNativeShadowData(slot, 27), splitsFar = TomNativeShadowData(slot, 28);
            float zDistance = -mul(UNITY_MATRIX_V, float4(position, 1)).z;
            [unroll] for (uint c = 0; c < 4; c++)
            {
                float3 delta = position - TomNativeShadowData(slot, 16 + c).xyz;
                bool inside = settings.w > .5 ? dot(delta, delta) < radii[c] : zDistance >= splitsNear[c] && zDistance < splitsFar[c];
                if (c < settings.x && inside && cascade == 4) cascade = c;
            }
            if (cascade == 4) return 1;
        }
        float3 coord = TomNativeShadowCoord(slot, cascade, position);
        if (any(coord.xy < 0) || any(coord.xy > 1) || coord.z < 0 || coord.z > 1) return 1;
        if (settings.y < .5) visibility = TomNativeShadowCompare(slot, coord.xy, coord.z);
        else
        {
            float2 offset = .5 * dimensions.zw;
            visibility = .25 * (TomNativeShadowCompare(slot, coord.xy + offset, coord.z)
                + TomNativeShadowCompare(slot, coord.xy - offset, coord.z)
                + TomNativeShadowCompare(slot, coord.xy + float2(offset.x, -offset.y), coord.z)
                + TomNativeShadowCompare(slot, coord.xy + float2(-offset.x, offset.y), coord.z));
        }
    }
    float4 fadeCenter = TomNativeShadowData(slot, 24), shadowData = TomNativeShadowData(slot, 21);
    float viewDistance = dot(_WorldSpaceCameraPos - position, UNITY_MATRIX_V[2].xyz);
    float fadeDistance = lerp(viewDistance, distance(position, fadeCenter.xyz), fadeCenter.w);
    float fade = saturate(fadeDistance * shadowData.z + shadowData.w);
    return lerp(1 - settings.z * (1 - visibility), 1, fade);
}
float TomNativeUnshadowedAttenuation(float3 position)
{
    #if defined(SPOT)
        float4 coord = mul(unity_WorldToLight, float4(position, 1));
        return (coord.z > 0) * UnitySpotCookie(coord) * UnitySpotAttenuate(coord.xyz);
    #elif defined(POINT)
        float3 coord = mul(unity_WorldToLight, float4(position, 1)).xyz;
        return tex2D(_LightTexture0, dot(coord, coord).rr).r;
    #elif defined(POINT_COOKIE)
        float3 coord = mul(unity_WorldToLight, float4(position, 1)).xyz;
        return tex2D(_LightTextureB0, dot(coord, coord).rr).r * texCUBE(_LightTexture0, coord).w;
    #elif defined(DIRECTIONAL_COOKIE)
        return tex2D(_LightTexture0, mul(unity_WorldToLight, float4(position, 1)).xy).w;
    #else
        return 1;
    #endif
}
float TomAlphaNativeLightAttenuation(float3 position, float existing)
{
    if (_TomBSDFNativeShadowParams.x != 1 || _TomBSDFNativeShadowParams.w < .5 || _TomBSDFReceiverOptOut > .5) return existing;
    #if defined(SPOT)
        const uint type = 1;
    #elif defined(POINT) || defined(POINT_COOKIE)
        const uint type = 2;
    #else
        const uint type = 0;
    #endif
    uint matched = 8, count = (uint)min(_TomBSDFNativeShadowParams.y, 8);
    [loop] for (uint slot = 0; slot < count; slot++)
    {
        float4 info = TomNativeShadowData(slot, 31);
        if (info.x != 1 || info.y != _TomBSDFNativeShadowParams.z || info.z != type) continue;
        float4 key = TomNativeShadowData(slot, 25);
        float3 delta = key.xyz - _WorldSpaceLightPos0.xyz;
        if (abs(key.w - _WorldSpaceLightPos0.w) > .01 || dot(delta, delta) > 1e-6) continue;
        // Identical light keys cannot be disambiguated from public Forward
        // uniforms. Falling back is preferable to shadowing the wrong light.
        if (matched != 8) return existing;
        matched = slot;
    }
    if (matched == 8) return existing;
    float4 nativeSize = TomNativeShadowData(matched, 26), copied = TomNativeShadowData(matched, 33);
    if (any(nativeSize.xy < 1) || any(nativeSize.xy > copied.xy / (type == 2 ? float2(3,2) : float2(1,1)))) return existing;
    return TomNativeUnshadowedAttenuation(position) * TomNativeShadowVisibility(matched, position, type);
}
#endif
