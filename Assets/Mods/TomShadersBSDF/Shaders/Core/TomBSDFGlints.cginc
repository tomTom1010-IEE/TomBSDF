#ifndef TOM_BSDF_GLINTS_INCLUDED
#define TOM_BSDF_GLINTS_INCLUDED

// Statistical footprint counting, following Deliot/Belcour (HPG 2023).
// The positive, moment-matched count below is an independent approximation;
// exact binomial and explicit-facet references live only in Tests.
uint TomGlintHash(uint x)
{
    x ^= x >> 16; x *= 0x7feb352du;
    x ^= x >> 15; x *= 0x846ca68bu;
    return x ^ (x >> 16);
}

uint TomGlintKey(int2 cell, uint seed)
{
    return TomGlintHash(asuint(cell.x) ^ TomGlintHash(asuint(cell.y) + seed));
}

float TomGlintUniform(uint key)
{
    return ((TomGlintHash(key) >> 8) + 0.5) * (1.0 / 16777216.0);
}

float TomGlintLogFailure(float p)
{
    if (p < 0.125)
        return p * (1.0 + p * (0.5 + p * (1.0/3.0 + p * (0.25 + p * (0.2 + p / 6.0)))));
    return -log(max(1.0 - p, 1e-20));
}

float3 TomGlintCountParameters(float n, float p)
{
    float mean = n * p;
    float a = TomGlintLogFailure(p);
    float x = n * a;
    float qx = x < 0.05 ? 1.0 + x * (-0.5 + x * (1.0/6.0 + x * (-1.0/24.0 + x/120.0)))
        : (1.0 - exp(-x)) / max(x, 1e-30);
    float q = min(x * qx, 1.0);
    float qMean = (a / max(p, 1e-30)) * qx;
    float edge = 0.15 * min(q, 1.0 - q);
    // Integral of the squared smooth Bernoulli gate is q - 9*edge/35.
    float gateMoment = 1.0 - (9.0/35.0) * edge / max(q, 1e-30);
    float variance = log(max((mean + 1.0 - p) * qMean / gateMoment, 1.0));
    return float3(q, rcp(max(qMean, 1e-30)), variance);
}

float TomGlintCount(float n, float p, float3 parameters, uint seed)
{
    float mean = n * p;
    float q = parameters.x;
    // A 24-bit random variate cannot resolve arbitrarily rare events. Preserve
    // their mean continuously rather than dropping tails or clipping HDR peaks.
    if (q <= 2e-6) return mean;
    if (p >= 1.0) return n;
    float edge = 0.15 * min(q, 1.0 - q);
    float gate = edge > 1e-8 ? 1.0 - smoothstep(q - edge, q + edge, TomGlintUniform(seed)) : 1.0;
    float u = TomGlintUniform(seed ^ 0x68bc21ebu);
    float v = TomGlintUniform(seed ^ 0x02e5be93u);
    float z = sqrt(-2.0 * log(u)) * cos(2.0 * TOM_BSDF_PI * v);
    float count = gate * parameters.y * exp(sqrt(parameters.z) * z - 0.5 * parameters.z);
    return lerp(mean, count, smoothstep(2e-6, 2e-4, q));
}

void TomGlintTriangle(float2 uv, out int2 a, out int2 b, out int2 c, out float3 weights)
{
    float2 skew = uv + (uv.x + uv.y) * 0.366025403784;
    a = (int2)floor(skew);
    float2 f = frac(skew);
    int2 step = f.x > f.y ? int2(1,0) : int2(0,1);
    b = a + step; c = a + 1;
    weights = float3(1.0 - max(f.x,f.y), abs(f.x-f.y), min(f.x,f.y));
}

struct TomGlintFootprint
{
    uint3 seeds0, seeds1, seeds2, seeds3;
    float3 trials0, trials1, trials2, trials3;
    float count, weight, ratio, intrinsicAlphaSquared;
};

float TomGlintDistribution(float d, float2 axes, float3 h, TomGlintFootprint footprint,
    float filteredAlphaSquared)
{
    if (footprint.weight <= 0.0 || d <= 0.0) return d;
    float largest = max(1.0, max(axes.x, axes.y));
    float peak = largest * largest; peak *= peak * TOM_BSDF_INV_PI / (axes.x * axes.y);
    float p = saturate(footprint.ratio * (d / peak));
    if (p <= 0.0) return d;
    // Angular spreading by AA/rough coat increases the effective count. This
    // filters variance, preserving the existing broadened lobe's expected D.
    float spreading = 1.0 + 1024.0 * max(filteredAlphaSquared - footprint.intrinsicAlphaSquared, 0.0);
    int2 angularA, angularB, angularC;
    float3 angularWeights;
    TomGlintTriangle(h.xy * 32.0, angularA, angularB, angularC, angularWeights);
    float reflected = 0.0;
    [loop] for (int grid = 0; grid < 4; ++grid)
    {
        uint3 seeds = grid == 0 ? footprint.seeds0 : (grid == 1 ? footprint.seeds1 : (grid == 2 ? footprint.seeds2 : footprint.seeds3));
        float3 trials = spreading * (grid == 0 ? footprint.trials0 : (grid == 1 ? footprint.trials1 : (grid == 2 ? footprint.trials2 : footprint.trials3)));
        [loop] for (int node = 0; node < 3; ++node)
        {
            float n = trials[node];
            if (n <= 0.0) continue;
            float3 parameters = TomGlintCountParameters(n, p);
            float value = angularWeights.x * TomGlintCount(n, p, parameters, TomGlintKey(angularA,seeds[node]));
            value += angularWeights.y * TomGlintCount(n, p, parameters, TomGlintKey(angularB,seeds[node]));
            value += angularWeights.z * TomGlintCount(n, p, parameters, TomGlintKey(angularC,seeds[node]));
            reflected += value;
        }
    }
    float sampledD = (peak / footprint.ratio) * reflected / (footprint.count * spreading);
    return lerp(d, sampledD, footprint.weight);
}
#endif
