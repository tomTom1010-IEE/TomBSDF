#ifndef TOM_BSDF_TYPES_INCLUDED
#define TOM_BSDF_TYPES_INCLUDED

#define TOM_BSDF_PI 3.14159265358979323846
#define TOM_BSDF_INV_PI 0.31830988618379067154
#define TOM_BSDF_MIN_ALPHA 0.001

struct TomBSDFMaterial
{
    float3 baseColor;
    float3 f0;
    float3 f90;
    float metalness;
    float roughness;
    float anisotropy;
    float anisotropyRotation;
    float diffuseRoughness;
    float occlusion;
    float3 emission;
};

struct TomBSDFGeometry
{
    float3 position;
    float3 geometricNormal;
    float3 smoothNormal;
    float3 normal;
    float3 tangent;
    float3 bitangent;
    float3 view;
};

struct TomBSDFLight
{
    float3 direction;
    float3 radiance;
    float attenuation; // Combined distance/cookie/shadow, applied exactly once.
};

struct TomBSDFEnergy
{
    float2 dfg;
    float missingAverage;
};

struct TomBSDFIndirect
{
    float3 irradianceOverPi;
    float3 prefilteredRadiance;
};

struct TomBSDFLobes
{
    float3 diffuse;
    float3 specular;
};

float3 TomSafeNormalize(float3 v)
{
    return v * rsqrt(max(dot(v, v), 1e-20));
}

float TomPow5(float x)
{
    float x2 = x * x;
    return x2 * x2 * x;
}

#endif
