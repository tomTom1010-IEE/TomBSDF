Shader "tom/BSDFCutout"
{
    Properties
    {
        _MainTex ("Base Color Map", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _MetallicMap ("Metallic Map", 2D) = "white" {}
        _RoughnessMap ("Roughness Map", 2D) = "white" {}
        _OcclusionMap ("Occlusion Map", 2D) = "white" {}
        _ORMMap ("Packed ORM Map", 2D) = "white" {}
        _EmissionMask ("Emission Map", 2D) = "black" {}
        _AlphaMask ("Coverage Mask", 2D) = "white" {}
        _AnisotropyMap ("Anisotropy Strength Map", 2D) = "white" {}
        _AnisotropyRotationMap ("Anisotropy Rotation Map", 2D) = "black" {}
        _NormalMapDetail ("Detail Normal Map", 2D) = "bump" {}
        _GlintMask ("Glint Weight Map (Linear R)", 2D) = "white" {}
        _GlintWeight ("Glint Weight", Range(0, 1)) = 0
        _GlintDensity ("Glint Density (Log10 per UV Area)", Range(0, 8)) = 6
        _GlintContrast ("Glint Contrast", Range(0, 1)) = 0.5
        _GlintSeed ("Glint Seed", Range(0, 65535)) = 0
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)
        _Metallic ("Metallic", Range(0, 1)) = 0
        _Roughness ("Perceptual Roughness", Range(0, 1)) = 0.5
        _DiffuseRoughness ("Diffuse Roughness", Range(0, 1)) = 0
        _IOR ("Dielectric IOR", Range(1, 3)) = 1.5
        _SpecularWeight ("Dielectric Specular Weight", Range(0, 1)) = 1
        _SpecularColor ("Dielectric Specular Color", Color) = (1, 1, 1, 1)
        [ToggleUI] _UseORM ("Use Packed ORM", Range(0, 1)) = 0
        _NormalMapScale ("Normal Strength", Range(0, 2)) = 1
        [Enum(UnityPacked,0,RGB,1,AG,2)] _NormalEncoding ("Normal Encoding", Range(0, 2)) = 0
        [ToggleUI] _NormalFlipY ("Flip Normal Y", Range(0, 1)) = 0
        [ToggleUI] _NormalDataRestore ("Restore SRGB Normal Data", Range(0, 1)) = 0
        _DetailNormalMapScale ("Detail Normal Strength", Range(0, 2)) = 0
        [Enum(UnityPacked,0,RGB,1,AG,2)] _DetailNormalEncoding ("Detail Normal Encoding", Range(0, 2)) = 0
        [ToggleUI] _DetailNormalFlipY ("Flip Detail Normal Y", Range(0, 1)) = 0
        [ToggleUI] _DetailNormalDataRestore ("Restore SRGB Detail Normal Data", Range(0, 1)) = 0
        _HeightMap ("Height Map (Linear R)", 2D) = "white" {}
        [Enum(Off,0,POM,1)] _ParallaxMode ("Parallax Mode", Range(0, 1)) = 0
        _HeightScale ("Height Depth (Meters)", Range(0, 0.2)) = 0
        [ToggleUI] _IsHeightReverse ("Is Height Reverse", Range(0, 1)) = 0
        [Enum(Realtime,0,Reference,1)] _ParallaxQuality ("Parallax Quality", Range(0, 1)) = 0
        _ParallaxFadeStart ("Parallax Fade Start (Meters)", Range(0, 100)) = 15
        _ParallaxFadeEnd ("Parallax Fade End (Meters)", Range(0, 100)) = 25
        _ParallaxGrazingFade ("Parallax Grazing Fade", Range(0.01, 0.5)) = 0.15
        _ParallaxMaxOffset ("Parallax Maximum UV Excursion", Range(0.01, 2)) = 0.25
        [ToggleUI] _ParallaxSelfShadow ("POM Local Self Shadow", Range(0, 1)) = 0
        _ParallaxSelfShadowStrength ("POM Self Shadow Strength", Range(0, 1)) = 1
        _ParallaxSelfShadowBias ("POM Self Shadow Bias Scale", Range(0, 4)) = 1
        _Anisotropy ("Anisotropy Strength", Range(0, 1)) = 0
        _AnisotropyRotation ("Anisotropy Rotation (Degrees)", Range(0, 360)) = 0
        _SpecularAAStrength ("Specular AA Strength", Range(0, 1)) = 1
        _SpecularAAVariance ("Specular AA Variance", Range(0, 1)) = 0.15
        _SpecularAAThreshold ("Specular AA Threshold", Range(0, 1)) = 0.2
        _CoatMask ("Coat Coverage Map", 2D) = "white" {}
        _CoatRoughnessMap ("Coat Roughness Map", 2D) = "white" {}
        _CoatWeight ("Coat Weight", Range(0, 1)) = 0
        _CoatIOR ("Coat IOR", Range(1, 2.5)) = 1.5
        _CoatRoughness ("Coat Roughness", Range(0, 1)) = 0.1
        _CoatNormalMap ("Coat Normal Map", 2D) = "bump" {}
        _CoatNormalScale ("Coat Normal Scale", Range(0, 4)) = 1
        _CoatNormalBaseBlend ("Coat Base Normal Inheritance", Range(0, 1)) = 0
        [Enum(UnityPacked,0,RGB,1,AG,2)] _CoatNormalEncoding ("Coat Normal Encoding", Range(0, 2)) = 0
        [ToggleUI] _CoatNormalFlipY ("Coat Normal Flip Y", Range(0, 1)) = 0
        [ToggleUI] _CoatNormalDataRestore ("Coat Normal Data Restore", Range(0, 1)) = 0
        _CoatThicknessMap ("Coat Thickness Map", 2D) = "white" {}
        _CoatAbsorptionColor ("Coat Transmission Color", Color) = (1, 1, 1, 1)
        _CoatAbsorptionDistance ("Coat Reference Distance (mm)", Range(0.001, 10)) = 1
        _CoatThickness ("Coat Thickness (mm)", Range(0, 2)) = 0.05
        _ThinFilmMask ("Thin Film Coverage Map", 2D) = "white" {}
        _ThinFilmThicknessMap ("Thin Film Thickness Map", 2D) = "white" {}
        _ThinFilmWeight ("Thin Film Weight", Range(0, 1)) = 0
        _ThinFilmIOR ("Thin Film IOR", Range(1, 3)) = 1.4
        [Enum(Realtime,0,Reference,1)] _ThinFilmQuality ("Thin Film Quality", Range(0, 1)) = 0
        _ThinFilmThickness ("Thin Film Thickness (nm)", Range(0, 2000)) = 400
        _Occlusion ("Occlusion", Range(0, 1)) = 1
        _OcclusionStrength ("Occlusion Strength", Range(0, 1)) = 1
        _IndirectDiffuseIntensity ("Indirect Diffuse Intensity", Range(0, 4)) = 1
        _ReflectionIntensity ("Probe Reflection Intensity", Range(0, 4)) = 1
        [ToggleUI] _ProbeBoxProjection ("Probe Box Projection", Range(0, 1)) = 1
        [ToggleUI] _ProbeBlending ("Blend Reflection Probes", Range(0, 1)) = 1
        _CustomSHVolumeBlend ("Tom SH Volume Blend", Range(0, 1)) = 1
        _SpecularOcclusionStrength ("Specular Occlusion Strength", Range(0, 1)) = 1
        _SpecularHorizonStrength ("Specular Horizon Strength", Range(0, 1)) = 1
        [ToggleUI] _SceneLighting ("Tom Scene Lighting", Range(0, 1)) = 1
        _AreaLightIntensity ("Area Light Intensity", Range(0, 4)) = 1
        [Enum(Realtime,0,Reference,1)] _AreaLightQuality ("Area Light Quality", Range(0, 1)) = 0
        _EmissionColor ("Emission Color", Color) = (0, 0, 0, 1)
        _EmissionIntensity ("Emission Intensity", Range(0, 20)) = 1
        _Coverage ("Coverage", Range(0, 1)) = 1
        _Cutoff ("Coverage Cutoff", Range(0, 1)) = 0.5
        [Enum(UnityEngine.Rendering.CullMode)] _CullOption ("Cull Mode", Range(0, 2)) = 2
        _ColorTextureMode ("Color Texture Input", Range(0, 2)) = 0
        _ColorValueMode ("Color Value Input", Range(0, 2)) = 0
        [ToggleUI] _DataTextureRestore ("Restore SRGB Material Data", Range(0, 1)) = 0
        _LightColorInput ("Unity Light Color Input", Range(0, 1)) = 0
        _ReflectionColorMode ("Probe Radiance Input", Range(0, 2)) = 0
        _CustomSHColorMode ("Tom SH Radiance Input", Range(0, 2)) = 0
        _DebugView ("Debug View", Range(0, 14)) = 0
        [HideInInspector][NonModifiableTextureData] _TomBSDFEnergyLUT ("TomBSDF Energy LUT v1", 2D) = "black" {}
        [HideInInspector][NonModifiableTextureData] _TomBSDFAnisoEnergyLUT ("TomBSDF Anisotropic Energy LUT v1", 3D) = "" {}
        [HideInInspector][NonModifiableTextureData] _TomBSDFFilmEnergyLUT ("TomBSDF Film Energy LUT v1", 3D) = "" {}
        [HideInInspector][NonModifiableTextureData] _TomBSDFRectLTC ("TomBSDF Rect LTC v1", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "Queue"="AlphaTest" "TomBSDFAreaVariants"="1" }
        LOD 400
        Cull [_CullOption]
        ZWrite On
        Pass
        {
            Name "ForwardBase"
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma target 4.5
            #pragma only_renderers d3d11
            #pragma vertex TomBSDFVertex
            #pragma fragment TomBSDFFragment
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap
            #pragma multi_compile __ UNITY_SPECCUBE_BOX_PROJECTION
            #pragma multi_compile __ UNITY_SPECCUBE_BLENDING
            #pragma multi_compile_fog
            #pragma multi_compile_local __ TOM_BSDF_AREA_REALTIME TOM_BSDF_AREA_REFERENCE
            #define TOM_BSDF_CUTOUT 1
            #define TOM_BSDF_PARALLAX 1
            #define TOM_BSDF_GLINTS 1
            #include "Passes/TomBSDFForward.cginc"
            ENDCG
        }
        Pass
        {
            Name "ForwardAdd"
            Tags { "LightMode"="ForwardAdd" }
            Blend One One, Zero One
            ZWrite Off
            ZTest LEqual
            CGPROGRAM
            #pragma target 4.5
            #pragma only_renderers d3d11
            #pragma vertex TomBSDFVertex
            #pragma fragment TomBSDFFragment
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            #define TOM_BSDF_CUTOUT 1
            #define TOM_BSDF_PARALLAX 1
            #define TOM_BSDF_GLINTS 1
            #include "Passes/TomBSDFForward.cginc"
            ENDCG
        }
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }
            ZWrite On
            ZTest LEqual
            CGPROGRAM
            #pragma target 4.5
            #pragma only_renderers d3d11
            #pragma vertex TomBSDFShadowVertex
            #pragma fragment TomBSDFShadowFragment
            #pragma multi_compile_shadowcaster
            #define TOM_BSDF_CUTOUT 1
            #include "Passes/TomBSDFShadow.cginc"
            ENDCG
        }
    }
    Fallback Off
}
