#ifndef TOM_BSDF_SURFACE_COORDINATES_INCLUDED
#define TOM_BSDF_SURFACE_COORDINATES_INCLUDED

struct TomSurfaceCoordinates
{
    float2 originalUV;
    float2 uv;
    float2 dx;
    float2 dy;
    float explicitGrad;
    float depth;
};

TomSurfaceCoordinates TomUnshiftedCoordinates(float2 uv)
{
    TomSurfaceCoordinates c = (TomSurfaceCoordinates)0;
    c.originalUV = uv;
    c.uv = uv;
    return c;
}

float4 TomSampleSurface(sampler2D map, float4 st, TomSurfaceCoordinates c)
{
    #if defined(TOM_BSDF_PARALLAX)
        [branch] if (c.explicitGrad > 0.5)
            return tex2Dgrad(map, TomUV(c.uv, st), c.dx * st.xy, c.dy * st.xy);
    #endif
    return tex2D(map, TomUV(c.uv, st));
}

float4 TomSampleSurfaceData(Texture2D map, SamplerState mapSampler, float4 st, TomSurfaceCoordinates c)
{
    #if defined(TOM_BSDF_PARALLAX)
        [branch] if (c.explicitGrad > 0.5)
            return map.SampleGrad(mapSampler, TomUV(c.uv, st), c.dx * st.xy, c.dy * st.xy);
    #endif
    return map.Sample(mapSampler, TomUV(c.uv, st));
}
#endif
