#ifndef TOM_BSDF_UNITY_COLOR_INCLUDED
#define TOM_BSDF_UNITY_COLOR_INCLUDED

// This is a KKS Linear-host adapter, even when its bundle is built in the Gamma
// modding template. Do not infer the player/target contract from compiler macros.
#define TOM_BSDF_KKS_LINEAR_CONTRACT 1

float3 TomSRGBToLinear(float3 c)
{
    c = max(c, 0.0);
    float3 decoded = lerp(pow((c + 0.055) / 1.055, 2.4), c / 12.92, step(c, 0.04045));
    return lerp(decoded, pow(c, 2.2), step(1.0, c));
}

float3 TomLinearToSRGB(float3 c)
{
    c = max(c, 0.0);
    float3 encoded = lerp(1.055 * pow(c, 1.0 / 2.4) - 0.055, 12.92 * c, step(c, 0.0031308));
    return lerp(encoded, pow(c, 1.0 / 2.2), step(1.0, c));
}

// 0: KKS Linear sampling/uniform convention; 1: explicit sRGB; 2: linear.
float3 TomColorInput(float3 c, float mode)
{
    if (mode > 1.5) return max(c, 0.0);
    if (mode > 0.5) return TomSRGBToLinear(c);
    return max(c, 0.0);
}

// Opt-in repair for data sampled through an sRGB view in the Linear player.
// This describes the sampled values, not the authoring project's import mode.
float3 TomDataInput(float3 c, float restoreSRGB)
{
    if (restoreSRGB > 0.5) return TomLinearToSRGB(c);
    return c;
}

float3 TomSceneOutput(float3 c)
{
    return c;
}

float3 TomSceneFog(float3 color, float3 fogColor, float visibility)
{
    return lerp(fogColor, color, saturate(visibility));
}

// UnityCG.DecodeHDR selects a Gamma shortcut at build time. Follow the KKS
// Linear RGBM instructions instead; native HDR uses w=0 (alpha is ignored).
float3 TomDecodeProbeHDR(float4 data, float4 instructions)
{
    float alpha = max(instructions.w * (data.a - 1.0) + 1.0, 0.0);
    return instructions.x * pow(alpha, instructions.y) * data.rgb;
}
#endif
