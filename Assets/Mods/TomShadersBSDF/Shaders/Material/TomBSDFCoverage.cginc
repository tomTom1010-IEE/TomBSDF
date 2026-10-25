#ifndef TOM_BSDF_COVERAGE_INCLUDED
#define TOM_BSDF_COVERAGE_INCLUDED

// Included after the input declarations and TomUV. Coverage is geometric
// presence, never Fresnel transmission, absorption or refracted background.
#if defined(TOM_BSDF_ALPHA)
    float _AlphaClip;
#endif

float TomCoverage(float2 uv)
{
    #if defined(TOM_BSDF_CUTOUT) || defined(TOM_BSDF_ALPHA)
        float alpha = tex2D(_MainTex, TomUV(uv, _MainTex_ST)).a;
        float mask = tex2D(_AlphaMask, TomUV(uv, _AlphaMask_ST)).r;
        mask = TomDataInput(mask.xxx, _DataTextureRestore).x;
        return saturate(alpha * mask * _Coverage);
    #else
        return 1.0;
    #endif
}

void TomClipCoverage(float coverage)
{
    #if defined(TOM_BSDF_CUTOUT)
        clip(coverage - max(_Cutoff, 1e-6));
    #elif defined(TOM_BSDF_ALPHA)
        clip(coverage - 1e-6);
        if (_AlphaClip > 0.5) clip(coverage - _Cutoff);
    #endif
}

float4 TomCoverageOutput(float3 color, float coverage)
{
    #if defined(TOM_BSDF_ALPHA)
        return float4(color * coverage, coverage);
    #else
        return float4(color, 1.0);
    #endif
}

#endif
