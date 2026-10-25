#ifndef TOM_BSDF_UNITY_PROBE_INCLUDED
#define TOM_BSDF_UNITY_PROBE_INCLUDED

// Tom Lighting Probes 0.2.x MPB contract. No dependency on X shading code.
Texture3D<float4> _TomSHVolumeTex;
SamplerState tom_sh_linear_clamp_sampler;
float4x4 _TomSHWorldToLocal;
float4 _TomSHBoundsMin, _TomSHBoundsInvSize, _TomSHVolumeGrid, _TomSHVolumeParams;

float3 TomSHBlockUV(float3 uv, float block)
{
    float3 grid = max(_TomSHVolumeGrid.xyz, 2.0);
    return float3((block * grid.x + 0.5 + uv.x * (grid.x - 1.0)) / max(_TomSHVolumeGrid.w, grid.x * 7.0),
        (0.5 + uv.y * (grid.y - 1.0)) / grid.y,
        (0.5 + uv.z * (grid.z - 1.0)) / grid.z);
}

float4 TomCustomSH(TomBSDFGeometry g)
{
    if (_CustomSHVolumeBlend <= 0.0 || _TomSHVolumeParams.x < 0.5) return 0.0;
    float3 position = mul(_TomSHWorldToLocal, float4(g.position, 1.0)).xyz;
    float3 uv = (position - _TomSHBoundsMin.xyz) * _TomSHBoundsInvSize.xyz;
    if (any(uv < 0.0) || any(uv > 1.0)) return 0.0;
    float3 edge = min(uv, 1.0 - uv);
    float distance = min(edge.x, min(edge.y, edge.z));
    float weight = _TomSHVolumeParams.z <= 0.0001 ? 1.0 : smoothstep(0.0, _TomSHVolumeParams.z, distance);
    float4 n = float4(g.normal, 1.0);
    float4 quadratic = n.xyzz * n.yzzx;
    float4 ar = _TomSHVolumeTex.SampleLevel(tom_sh_linear_clamp_sampler, TomSHBlockUV(uv, 0.0), 0);
    float4 ag = _TomSHVolumeTex.SampleLevel(tom_sh_linear_clamp_sampler, TomSHBlockUV(uv, 1.0), 0);
    float4 ab = _TomSHVolumeTex.SampleLevel(tom_sh_linear_clamp_sampler, TomSHBlockUV(uv, 2.0), 0);
    float4 br = _TomSHVolumeTex.SampleLevel(tom_sh_linear_clamp_sampler, TomSHBlockUV(uv, 3.0), 0);
    float4 bg = _TomSHVolumeTex.SampleLevel(tom_sh_linear_clamp_sampler, TomSHBlockUV(uv, 4.0), 0);
    float4 bb = _TomSHVolumeTex.SampleLevel(tom_sh_linear_clamp_sampler, TomSHBlockUV(uv, 5.0), 0);
    float3 c = _TomSHVolumeTex.SampleLevel(tom_sh_linear_clamp_sampler, TomSHBlockUV(uv, 6.0), 0).rgb;
    float3 value = float3(dot(ar, n), dot(ag, n), dot(ab, n))
        + float3(dot(br, quadratic), dot(bg, quadratic), dot(bb, quadratic))
        + c * (n.x * n.x - n.y * n.y);
    // Unity 2019 AddDirectionalLight uses a peak-normalized L2 cosine kernel
    // with doubled input (L0=8/17, L1=16/17, L2 coefficient=5/17).
    // TomProbe 0.2.x integrates it with dOmega/pi. Undo that 32/17 gain here
    // to obtain irradiance/pi; leave the shared atlas and X receivers unchanged.
    value *= 17.0 / 32.0;
    // Legacy Gamma capture integrated host-encoded radiance. Decoding after SH
    // evaluation is an approximation, not an exact linear-radiance integral.
    // Decode before intensity/fading; never transform signed coefficients.
    value = TomColorInput(max(value, 0.0), _CustomSHColorMode) * max(_TomSHVolumeParams.y, 0.0);
    return float4(value, weight * saturate(_CustomSHVolumeBlend));
}

float3 TomUnityDiffuseEnvironment(TomBSDFGeometry g)
{
    float4 normal = float4(g.normal, 1.0);
    float3 native = max(SHEvalLinearL0L1(normal) + SHEvalLinearL2(normal), 0.0);
    float4 custom = TomCustomSH(g);
    return lerp(native, custom.rgb, custom.a);
}

float3 TomUnityProbeEnvironment(TomBSDFMaterial m, TomBSDFGeometry g)
{
    float3 reflection = TomSpecularReflection(m, g);
    float3 direction0 = reflection;
    #if defined(UNITY_SPECCUBE_BOX_PROJECTION)
        if (_ProbeBoxProjection > 0.5)
            direction0 = BoxProjectedCubemapDirection(reflection, g.position,
                unity_SpecCube0_ProbePosition, unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax);
    #endif
    float mip = m.roughness * (1.7 - 0.7 * m.roughness) * UNITY_SPECCUBE_LOD_STEPS;
    float4 sample0 = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, direction0, mip);
    float3 radiance0 = TomColorInput(TomDecodeProbeHDR(sample0, unity_SpecCube0_HDR), _ReflectionColorMode);
    #if defined(UNITY_SPECCUBE_BLENDING)
        float weight = saturate(unity_SpecCube0_BoxMin.w);
        if (_ProbeBlending > 0.5 && weight < 0.99999)
        {
            float3 direction1 = reflection;
            #if defined(UNITY_SPECCUBE_BOX_PROJECTION)
                if (_ProbeBoxProjection > 0.5)
                    direction1 = BoxProjectedCubemapDirection(reflection, g.position,
                        unity_SpecCube1_ProbePosition, unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax);
            #endif
            float4 sample1 = UNITY_SAMPLE_TEXCUBE_SAMPLER_LOD(unity_SpecCube1, unity_SpecCube0, direction1, mip);
            float3 radiance1 = TomColorInput(TomDecodeProbeHDR(sample1, unity_SpecCube1_HDR), _ReflectionColorMode);
            // Blend decoded radiance, not gamma-encoded colors or BRDF results.
            return lerp(radiance1, radiance0, weight);
        }
    #endif
    return radiance0;
}
#endif
