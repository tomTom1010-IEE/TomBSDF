#ifndef TOM_BSDF_INPUTS_INCLUDED
#define TOM_BSDF_INPUTS_INCLUDED
#include "../Platform/Unity2019/TomBSDFColor.cginc"

sampler2D _MainTex, _AlphaMask, _NormalMap, _EmissionMask;
sampler2D _NormalMapDetail;
sampler2D _MetallicMap, _OcclusionMap, _ORMMap;
UNITY_DECLARE_TEX2D(_RoughnessMap);
sampler2D _TomBSDFEnergyLUT;
// Scalar maps share the material-data sampler to stay inside D3D11's 16 slots.
UNITY_DECLARE_TEX2D_NOSAMPLER(_AnisotropyMap);
UNITY_DECLARE_TEX2D_NOSAMPLER(_AnisotropyRotationMap);
UNITY_DECLARE_TEX2D_NOSAMPLER(_CoatMask);
UNITY_DECLARE_TEX2D_NOSAMPLER(_CoatRoughnessMap);
UNITY_DECLARE_TEX2D_NOSAMPLER(_CoatNormalMap);
UNITY_DECLARE_TEX2D_NOSAMPLER(_CoatThicknessMap);
UNITY_DECLARE_TEX2D_NOSAMPLER(_ThinFilmMask);
UNITY_DECLARE_TEX2D_NOSAMPLER(_ThinFilmThicknessMap);
float4 _CoatMask_ST, _CoatRoughnessMap_ST, _CoatNormalMap_ST, _CoatThicknessMap_ST;
float4 _ThinFilmMask_ST, _ThinFilmThicknessMap_ST;
float _CoatWeight, _CoatIOR, _CoatRoughness, _CoatNormalScale, _CoatNormalBaseBlend;
float _CoatNormalEncoding, _CoatNormalFlipY, _CoatNormalDataRestore;
float4 _CoatAbsorptionColor;
float _CoatAbsorptionDistance, _CoatThickness;
float _ThinFilmWeight, _ThinFilmIOR, _ThinFilmThickness, _ThinFilmQuality;
float4 _MainTex_ST, _AlphaMask_ST, _NormalMap_ST, _EmissionMask_ST;
float4 _NormalMapDetail_ST;
float4 _AnisotropyMap_ST, _AnisotropyRotationMap_ST;
float _Anisotropy, _AnisotropyRotation;
float4 _MetallicMap_ST, _RoughnessMap_ST, _OcclusionMap_ST, _ORMMap_ST;
float4 _BaseColor, _SpecularColor, _EmissionColor;
float _Metallic, _Roughness, _DiffuseRoughness, _IOR, _SpecularWeight;
float _Occlusion, _OcclusionStrength, _EmissionIntensity, _UseORM;
float _NormalMapScale, _NormalEncoding, _NormalFlipY, _NormalDataRestore;
float _DetailNormalMapScale, _DetailNormalEncoding, _DetailNormalFlipY, _DetailNormalDataRestore;
float _SpecularAAStrength, _SpecularAAVariance, _SpecularAAThreshold;
float _ProbeBoxProjection, _ProbeBlending, _ReflectionColorMode;
float _CustomSHVolumeBlend, _CustomSHColorMode;
float _SpecularOcclusionStrength, _SpecularHorizonStrength;
float _ColorTextureMode, _ColorValueMode, _DataTextureRestore, _LightColorInput;
float _Coverage, _Cutoff, _IndirectDiffuseIntensity, _ReflectionIntensity;
float _DebugView;

float2 TomUV(float2 uv, float4 st) { return uv * st.xy + st.zw; }
#include "TomBSDFSurfaceCoordinates.cginc"
#if defined(TOM_BSDF_PARALLAX) || defined(TOM_BSDF_TESSELLATION)
    #include "TomBSDFHeight.cginc"
#endif
#include "TomBSDFCoverage.cginc"
#endif
