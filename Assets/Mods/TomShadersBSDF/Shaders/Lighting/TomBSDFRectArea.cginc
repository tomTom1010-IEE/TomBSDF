#ifndef TOM_BSDF_RECT_AREA_INCLUDED
#define TOM_BSDF_RECT_AREA_INCLUDED

// LTC tables: Heitz, Dupuy, Hill, Neubelt, SIGGRAPH 2016. See ThirdParty/LTC-LICENSE.txt.
// The table is used only for bare isotropic single scattering. The existing
// complete BRDF handles residuals and the sampled anisotropic/layered path.
Texture2D<float4> _TomBSDFRectLTC;
float _SceneLighting, _AreaLightIntensity, _AreaLightQuality;
float4 _TomBSDFSceneParams;
float4 _TomBSDFRectCenter[4], _TomBSDFRectRight[4], _TomBSDFRectUp[4], _TomBSDFRectRadiance[4];

struct TomRectLight
{
    float3 center, x, y, normal, radiance;
    float area;
};

struct TomAreaApproximation
{
    float3x3 inverse;
    float3 weight;
    float3 broadWeight;
    float determinant;
    bool active;
};

float3x3 TomAreaFrame(TomBSDFGeometry g)
{
    float3 tangent = g.view - g.normal * dot(g.normal, g.view);
    if (dot(tangent, tangent) < 1e-8) tangent = g.tangent;
    tangent = TomSafeNormalize(tangent);
    return float3x3(tangent, cross(g.normal, tangent), g.normal);
}

bool TomAreaActive()
{
    return _SceneLighting > 0.5 && _AreaLightIntensity > 0.0
        && abs(_TomBSDFSceneParams.x - 1.0) < 0.01
        && _TomBSDFSceneParams.z > 0.5 && _TomBSDFSceneParams.y > 0.5;
}

bool TomReadRect(int index, float3 position, out TomRectLight light)
{
    light.center = _TomBSDFRectCenter[index].xyz;
    light.x = _TomBSDFRectRight[index].xyz;
    light.y = _TomBSDFRectUp[index].xyz;
    float3 crossXY = cross(light.x, light.y);
    light.area = 4.0 * length(crossXY);
    light.normal = TomSafeNormalize(crossXY);
    light.radiance = max(_TomBSDFRectRadiance[index].rgb, 0.0) * _AreaLightIntensity;
    return light.area > 1e-8 && (_TomBSDFRectRight[index].w > 0.5
        || dot(position - light.center, light.normal) > 1e-6);
}

void TomAreaClip(float3 vertices[8], int count, float3 plane,
    out float3 clipped[8], out int written)
{
    // Separate input/output storage: avoid FXC's dynamic inout-array copy-back
    // and undefined unused elements when this clipper is inlined twice.
    [unroll] for (int init = 0; init < 8; init++) clipped[init] = 0.0;
    written = 0;
    float3 previous = vertices[max(count - 1, 0)];
    float dp = dot(previous, plane);
    [loop] for (int j = 0; j < count; j++)
    {
        float3 current = vertices[j];
        float dc = dot(current, plane);
        if ((dp > 0.0) != (dc > 0.0))
        {
            clipped[written] = lerp(previous, current, dp / (dp - dc));
            written++;
        }
        if (dc > 0.0)
        {
            clipped[written] = current;
            written++;
        }
        previous = current; dp = dc;
    }
}

float TomAreaPolygon(TomRectLight light, TomBSDFGeometry g, float3x3 inverseLTC)
{
    float3x3 frame = TomAreaFrame(g);
    float3 vertices[8];
    vertices[0] = light.center - light.x - light.y - g.position;
    vertices[1] = light.center + light.x - light.y - g.position;
    vertices[2] = light.center + light.x + light.y - g.position;
    vertices[3] = light.center - light.x + light.y - g.position;
    [unroll] for (int init = 4; init < 8; init++) vertices[init] = 0.0;
    float3 clipped[8];
    int count;
    // Clip the physical mesh horizon before the transformed shading horizon.
    TomAreaClip(vertices, 4, g.geometricNormal, clipped, count);
    [loop] for (int j = 0; j < count; j++) clipped[j] = mul(inverseLTC, mul(frame, clipped[j]));
    int transformedCount = count;
    TomAreaClip(clipped, transformedCount, float3(0, 0, 1), vertices, count);
    if (count < 3) return 0.0;
    float sum = 0.0;
    float3 previous = TomSafeNormalize(vertices[count - 1]);
    [loop] for (int k = 0; k < count; k++)
    {
        float3 current = TomSafeNormalize(vertices[k]);
        float3 c = cross(previous, current);
        float sine = length(c);
        sum += c.z * atan2(sine, clamp(dot(previous, current), -1.0, 1.0)) / max(sine, 1e-8);
        previous = current;
    }
    return abs(sum) * (0.5 * TOM_BSDF_INV_PI);
}

float TomRectPDF(TomRectLight light, float3 position, float3 direction)
{
    float cosine = dot(light.normal, direction);
    float distance = dot(light.center - position, light.normal) / (abs(cosine) > 1e-8 ? cosine : 1e-8);
    if (distance <= 0.0 || abs(cosine) < 1e-8) return 0.0;
    float3 offset = position + direction * distance - light.center;
    float xx = dot(light.x, light.x), yy = dot(light.y, light.y), xy = dot(light.x, light.y);
    float determinant = max(xx * yy - xy * xy, 1e-20);
    float2 rhs = float2(dot(offset, light.x), dot(offset, light.y));
    float2 uv = float2(yy * rhs.x - xy * rhs.y, xx * rhs.y - xy * rhs.x) / determinant;
    if (any(abs(uv) > 1.00001)) return 0.0;
    return distance * distance / max(light.area * abs(cosine), 1e-12);
}

float TomAreaVNDFPDF(TomBSDFMaterial m, TomBSDFGeometry g, float3 l)
{
    float3 v = TomInAnisotropicFrame(g, g.view);
    if (v.z <= 0.0) return 0.0;
    float3 h = TomInAnisotropicFrame(g, TomSafeNormalize(g.view + l));
    if (h.z <= 0.0 || dot(g.view, l) < -0.999999) return 0.0;
    float2 axes = TomAnisotropicAxes(m.roughness, m.anisotropy);
    return TomAnisotropicGGX(h, axes) / max(2.0 * (v.z + length(float3(axes * v.xy, v.z))), 1e-10);
}

float3 TomAreaVNDFSample(TomBSDFMaterial m, TomBSDFGeometry g, float2 u)
{
    float3 v = TomInAnisotropicFrame(g, g.view);
    if (v.z <= 0.0) return -g.normal;
    float3 h = TomLayerVNDF(v, TomAnisotropicAxes(m.roughness, m.anisotropy), u);
    return reflect(-g.view, g.tangent * h.x + g.bitangent * h.y + g.normal * h.z);
}

float2 TomAreaSequence(uint j, uint count, uint proposal)
{
    float radical = reversebits(j) * 2.3283064365386963e-10;
    return frac(float2((j + 0.5) / count, radical) + float2(0.173 * proposal, 0.379 * proposal));
}

float3 TomAreaSampled(TomBSDFMaterial m, TomBSDFGeometry g, TomBSDFEnergy ev,
    TomBSDFLayers layers, bool coated, TomRectLight rect, uint count, TomAreaApproximation approximation)
{
    float3 color = 0.0;
    uint proposals = coated ? 4 : 3;
    float3x3 frame = TomAreaFrame(g);
    [loop] for (uint proposal = 0; proposal < proposals; proposal++)
    [loop] for (uint j = 0; j < count; j++)
    {
        float2 u = TomAreaSequence(j, count, proposal);
        float3 direction;
        if (proposal == 0)
            direction = TomSafeNormalize(rect.center + rect.x * (2.0 * u.x - 1.0) + rect.y * (2.0 * u.y - 1.0) - g.position);
        else if (proposal == 3)
        {
            float radius = sqrt(u.x), angle = 2.0 * TOM_BSDF_PI * u.y;
            direction = g.tangent * (radius * cos(angle)) + g.bitangent * (radius * sin(angle)) + g.normal * sqrt(1.0 - u.x);
        }
        else if (!coated && proposal == 2)
        {
            float radius = sqrt(u.x), angle = 2.0 * TOM_BSDF_PI * u.y;
            direction = g.tangent * (radius * cos(angle)) + g.bitangent * (radius * sin(angle)) + g.normal * sqrt(1.0 - u.x);
        }
        else if (proposal == 2)
            direction = TomAreaVNDFSample(layers.coat, layers.coatGeometry, u);
        else if (coated && u.x < layers.weight)
            direction = TomAreaVNDFSample(layers.substrate, g, float2(u.x / max(layers.weight, 1e-6), u.y));
        else
        {
            if (coated) u.x = (u.x - layers.weight) / max(1.0 - layers.weight, 1e-6);
            direction = TomAreaVNDFSample(m, g, u);
        }
        float areaPDF = TomRectPDF(rect, g.position, direction);
        if (areaPDF <= 0.0) continue;
        float specPDF = TomAreaVNDFPDF(m, g, direction);
        float coatPDF = 0.0;
        float cosinePDF = saturate(dot(g.normal, direction)) * TOM_BSDF_INV_PI;
        if (coated)
        {
            specPDF = lerp(specPDF, TomAreaVNDFPDF(layers.substrate, g, direction), layers.weight);
            coatPDF = TomAreaVNDFPDF(layers.coat, layers.coatGeometry, direction);
        }
        TomBSDFLight light;
        light.direction = direction; light.radiance = rect.radiance; light.attenuation = 1.0;
        float3 value;
        if (coated) value = TomEvaluateLayerLight(m, g, ev, layers, light);
        else value = TomEvaluateLight(m, g, ev, light);
        if (approximation.active)
        {
            float3 q = mul(approximation.inverse, mul(frame, direction));
            float q2 = dot(q, q);
            float pdf = approximation.determinant * max(q.z, 0.0) * TOM_BSDF_INV_PI / max(q2 * q2, 1e-20);
            if (dot(g.geometricNormal, direction) <= 0.0) pdf = 0.0;
            float broadPDF = dot(g.geometricNormal, direction) > 0.0 ? cosinePDF : 0.0;
            value -= (pdf * approximation.weight + broadPDF * approximation.broadWeight) * rect.radiance;
        }
        color += value / max(count * (areaPDF + specPDF + coatPDF + cosinePDF), 1e-12);
    }
    return color;
}

TomAreaApproximation TomAreaApproximate(TomBSDFMaterial m, TomBSDFGeometry g, TomBSDFEnergy ev, bool active)
{
    TomAreaApproximation approximation = (TomAreaApproximation)0;
    approximation.active = active;
    if (!active) return approximation;
    float2 coordinates = float2(sqrt(max(m.roughness * m.roughness, TOM_BSDF_MIN_ALPHA)), sqrt(1.0 - saturate(dot(g.normal, g.view)))) * 63.0 + 0.5;
    float4 coefficients = _TomBSDFRectLTC.SampleLevel(tom_aniso_linear_clamp_sampler, coordinates / float2(128, 64), 0);
    float4 amplitude = _TomBSDFRectLTC.SampleLevel(tom_aniso_linear_clamp_sampler, (coordinates + float2(64, 0)) / float2(128, 64), 0);
    approximation.inverse = float3x3(coefficients.x, 0, coefficients.z, 0, 1, 0, coefficients.y, 0, coefficients.w);
    approximation.weight = m.f0 * amplitude.x + (m.f90 - m.f0) * amplitude.y;
    TomBSDFMaterial dielectric = TomDielectricPart(m);
    approximation.broadWeight = (1.0 - m.metalness) * (1.0 - saturate(TomSpecularAlbedo(dielectric, ev)))
        * TomEONAlbedo(saturate(dot(g.normal, g.view)), m.diffuseRoughness, m.baseColor)
        + TomMultiScatterColor(m, ev) * saturate(1.0 - ev.dfg.x - ev.dfg.y);
    approximation.determinant = abs(coefficients.x * coefficients.w - coefficients.y * coefficients.z);
    return approximation;
}

float3 TomEvaluateRectLights(TomBSDFMaterial m, TomBSDFGeometry g, TomBSDFEnergy ev, TomBSDFLayers layers, bool coated)
{
    if (!TomAreaActive() || dot(g.geometricNormal, g.view) <= 0.0) return 0.0;
    uint width, height;
    _TomBSDFRectLTC.GetDimensions(width, height);
    #if defined(TOM_BSDF_AREA_REFERENCE)
        bool useLTC = false;
        uint samples = 128;
    #elif defined(TOM_BSDF_AREA_REALTIME)
        bool useLTC = !coated && dot(g.normal, g.view) > 0.0 && m.anisotropy <= 0.0 && _AreaLightQuality < 0.5 && width == 128 && height == 64;
        uint samples = useLTC ? 16 : 32;
    #else
        // Preserved dynamic path for the independent numerical/reference probes.
        bool useLTC = !coated && dot(g.normal, g.view) > 0.0 && m.anisotropy <= 0.0 && _AreaLightQuality < 0.5 && width == 128 && height == 64;
        uint samples = useLTC ? 16 : (_AreaLightQuality > 0.5 ? 128 : 32);
    #endif
    TomAreaApproximation approximation = TomAreaApproximate(m, g, ev, useLTC);
    float3 result = 0.0;
    int count = min(4, (int)_TomBSDFSceneParams.y);
    [loop] for (int index = 0; index < count; index++)
    {
        TomRectLight rect;
        if (!TomReadRect(index, g.position, rect)) continue;
        if (useLTC)
            result += (TomAreaPolygon(rect, g, approximation.inverse) * approximation.weight
                + TomAreaPolygon(rect, g, float3x3(1,0,0,0,1,0,0,0,1)) * approximation.broadWeight) * rect.radiance;
        result += TomAreaSampled(m, g, ev, layers, coated, rect, samples, approximation);
    }
    return result;
}
#endif
