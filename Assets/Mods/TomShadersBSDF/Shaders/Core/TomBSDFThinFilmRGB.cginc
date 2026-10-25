#ifndef TOM_BSDF_THIN_FILM_RGB_INCLUDED
#define TOM_BSDF_THIN_FILM_RGB_INCLUDED
#include "TomBSDFTypes.cginc"

// Channel-specific Airy spectra evaluated in RGB lanes; no channel or harmonic reduction.
float3 TomFilmSensitivityRGB(float opdNM, float3 phaseShift, float opdVarianceNM)
{
    float phase = 2.0 * TOM_BSDF_PI * opdNM * 1e-9;
    float3 frequency = float3(1.6810e6, 1.7953e6, 2.2084e6);
    float3 variance = float3(4.3278e9, 9.3046e9, 6.6121e9);
    float3 amplitude = float3(5.4856e-13, 4.4201e-13, 5.2481e-13);
    float3 envelope = amplitude * sqrt(2.0 * TOM_BSDF_PI * variance)
        * exp(-variance * phase * phase)
        * exp(-0.5 * (2.0 * TOM_BSDF_PI * 1e-9) * (2.0 * TOM_BSDF_PI * 1e-9)
            * frequency * frequency * opdVarianceNM);
    float3 x = envelope.x * cos(frequency.x * phase + phaseShift);
    float3 y = envelope.y * cos(frequency.y * phase + phaseShift);
    float3 z = envelope.z * cos(frequency.z * phase + phaseShift);
    float extraFrequency = 2.2399e6;
    x += 9.7470e-14 * sqrt(2.0 * TOM_BSDF_PI * 4.5282e9)
        * exp(-4.5282e9 * phase * phase) * cos(extraFrequency * phase + phaseShift)
        * exp(-0.5 * pow(2.0 * TOM_BSDF_PI * 1e-9 * extraFrequency, 2.0) * opdVarianceNM);
    x /= 1.0685e-7; y /= 1.0685e-7; z /= 1.0685e-7;
    return x * float3(3.2406, -0.9689, 0.0557)
        + y * float3(-1.5372, 1.8758, -0.2040)
        + z * float3(-0.4986, 0.0415, 1.0570);
}

float3 TomFilmPolarizedRGB(float r12, float3 r23Real, float3 r23Imag,
    float opd, float opdVariance)
{
    float first = r12 * r12;
    float3 second = min(r23Real * r23Real + r23Imag * r23Imag, 1.0);
    float3 product = min(first * second, 0.999999);
    float3 remaining = (1.0 - first) * (1.0 - second) / max(1.0 - product, 1e-6);
    float3 result = 1.0 - remaining;
    float3 coefficient = -remaining;
    float3 phaseReal = float3(second.x > 0.0 ? r23Real.x : 1.0,
        second.y > 0.0 ? r23Real.y : 1.0, second.z > 0.0 ? r23Real.z : 1.0);
    float3 phaseImag = float3(second.x > 0.0 ? r23Imag.x : 0.0,
        second.y > 0.0 ? r23Imag.y : 0.0, second.z > 0.0 ? r23Imag.z : 0.0);
    float3 phase = atan2(phaseImag, phaseReal) + (r12 < 0.0 ? TOM_BSDF_PI : 0.0);
    [loop] for (int order = 1; order <= 16; ++order)
    {
        coefficient *= -sqrt(product);
        if (all(abs(coefficient) < 1e-6) || order * opd > 16000.0) break;
        float3 active = float3(abs(coefficient.x) >= 1e-6,
            abs(coefficient.y) >= 1e-6, abs(coefficient.z) >= 1e-6);
        float3 response = TomFilmSensitivityRGB(order * opd, order * phase,
            order * order * opdVariance);
        result += 2.0 * coefficient * response * active;
    }
    return result;
}

void TomComplexDivideRGB(float3 ar, float3 ai, float3 br, float3 bi,
    out float3 realPart, out float3 imaginaryPart)
{
    float3 denominator = max(br * br + bi * bi, 1e-20);
    realPart = (ar * br + ai * bi) / denominator;
    imaginaryPart = (ai * br - ar * bi) / denominator;
}

float3 TomFilmChannelsRGB(float mu, float incidentIOR, float filmIOR,
    float3 bottomN, float3 bottomK, float thicknessNM, float thicknessVariance)
{
    float sinSquared = incidentIOR * incidentIOR * (1.0 - mu * mu);
    float filmCosSquared = 1.0 - sinSquared / (filmIOR * filmIOR);
    if (filmCosSquared <= 0.0) return 1.0;
    float filmCos = sqrt(filmCosSquared);
    float3 nReal = bottomN * bottomN - bottomK * bottomK;
    float3 nImag = 2.0 * bottomN * bottomK;
    float3 qr = nReal - sinSquared;
    // Keep the scalar oracle's length operation at the TIR cancellation boundary.
    float3 modulus = float3(length(float2(qr.x, nImag.x)),
        length(float2(qr.y, nImag.y)), length(float2(qr.z, nImag.z)));
    float3 qReal = sqrt(max(0.5 * (modulus + qr), 0.0));
    float3 signImag = float3(nImag.x < 0.0 ? -1.0 : 1.0,
        nImag.y < 0.0 ? -1.0 : 1.0, nImag.z < 0.0 ? -1.0 : 1.0);
    float3 qImag = signImag * sqrt(max(0.5 * (modulus - qr), 0.0));
    // On the real axis the generic complex sqrt loses precision by cancellation
    // at TIR. Its exact real-axis limit must not invent a transmitted component.
    float3 realAxis = float3(nImag.x == 0.0, nImag.y == 0.0, nImag.z == 0.0);
    qReal = lerp(qReal, sqrt(max(qr, 0.0)), realAxis);
    qImag = lerp(qImag, sqrt(max(-qr, 0.0)), realAxis);
    float firstS = (incidentIOR * mu - filmIOR * filmCos) / max(incidentIOR * mu + filmIOR * filmCos, 1e-6);
    float firstP = (filmIOR * mu - incidentIOR * filmCos) / max(filmIOR * mu + incidentIOR * filmCos, 1e-6);
    float3 secondSR, secondSI, secondPR, secondPI;
    TomComplexDivideRGB(filmIOR * filmCos - qReal, -qImag,
        filmIOR * filmCos + qReal, qImag, secondSR, secondSI);
    TomComplexDivideRGB(nReal * filmCos - filmIOR * qReal,
        nImag * filmCos - filmIOR * qImag,
        nReal * filmCos + filmIOR * qReal, nImag * filmCos + filmIOR * qImag, secondPR, secondPI);
    float opticalFactor = 2.0 * filmIOR * filmCos;
    float opd = opticalFactor * thicknessNM;
    float variance = opticalFactor * opticalFactor * thicknessVariance;
    return 0.5 * (TomFilmPolarizedRGB(firstS, secondSR, secondSI, opd, variance)
        + TomFilmPolarizedRGB(firstP, secondPR, secondPI, opd, variance));
}


#endif

