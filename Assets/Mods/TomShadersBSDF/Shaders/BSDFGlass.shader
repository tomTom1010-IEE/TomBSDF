Shader "tom/BSDFGlass"
{
    Properties
    {
        _MainTex ("Absorption Reference Map", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "bump" {}
        _NormalMapDetail ("Detail Normal Map", 2D) = "bump" {}
        _RoughnessMap ("Roughness Map", 2D) = "white" {}
        _OcclusionMap ("Occlusion Map", 2D) = "white" {}
        _EmissionMask ("Emission Map", 2D) = "black" {}
        _AlphaMask ("Coverage Mask", 2D) = "white" {}
        _AnisotropyMap ("Anisotropy Strength Map", 2D) = "white" {}
        _AnisotropyRotationMap ("Anisotropy Rotation Map", 2D) = "black" {}
        _GlassThicknessMap ("Thickness Map", 2D) = "white" {}
        _BaseColor ("Absorption Reference Color", Color) = (1, 1, 1, 1)
        _IOR ("Dielectric IOR", Range(1, 3)) = 1.5
        _Roughness ("Perceptual Roughness", Range(0, 1)) = 0.1
        _NormalMapScale ("Normal Strength", Range(0, 2)) = 1
        [Enum(UnityPacked,0,RGB,1,AG,2)] _NormalEncoding ("Normal Encoding", Range(0, 2)) = 0
        [ToggleUI] _NormalFlipY ("Flip Normal Y", Range(0, 1)) = 0
        [ToggleUI] _NormalDataRestore ("Restore SRGB Normal Data", Range(0, 1)) = 0
        _DetailNormalMapScale ("Detail Normal Strength", Range(0, 2)) = 0
        [Enum(UnityPacked,0,RGB,1,AG,2)] _DetailNormalEncoding ("Detail Normal Encoding", Range(0, 2)) = 0
        [ToggleUI] _DetailNormalFlipY ("Flip Detail Normal Y", Range(0, 1)) = 0
        [ToggleUI] _DetailNormalDataRestore ("Restore SRGB Detail Normal Data", Range(0, 1)) = 0
        _Anisotropy ("Anisotropy Strength", Range(0, 1)) = 0
        _AnisotropyRotation ("Anisotropy Rotation (Degrees)", Range(0, 360)) = 0
        _SpecularAAStrength ("Specular AA Strength", Range(0, 1)) = 1
        _SpecularAAVariance ("Specular AA Variance", Range(0, 1)) = 0.15
        _SpecularAAThreshold ("Specular AA Threshold", Range(0, 1)) = 0.2
        _GlassThickness ("Glass Thickness (m)", Range(0, 1)) = 0.01
        _GlassAbsorptionColor ("Absorption Color At Distance", Color) = (1, 1, 1, 1)
        _GlassAbsorptionDistance ("Absorption Reference Distance (m)", Range(0.0001, 10)) = 0.1
        [ToggleUI] _UseSceneRefraction ("Use Scene Refraction", Range(0, 1)) = 1
        [Enum(Full,1,Half,2)] _GlassBufferResolution ("Refraction Buffer Resolution", Range(1, 2)) = 1
        _GlassDepthBias ("Refraction Depth Guard (m)", Range(0, 0.1)) = 0.002
        _GlassEdgeFade ("Refraction Screen Edge Fade", Range(0, 0.2)) = 0.02
        _Occlusion ("Occlusion", Range(0, 1)) = 1
        _OcclusionStrength ("Occlusion Strength", Range(0, 1)) = 1
        _ReflectionIntensity ("Probe Reflection Intensity", Range(0, 4)) = 1
        [ToggleUI] _ProbeBoxProjection ("Probe Box Projection", Range(0, 1)) = 1
        [ToggleUI] _ProbeBlending ("Blend Reflection Probes", Range(0, 1)) = 1
        _SpecularOcclusionStrength ("Specular Occlusion Strength", Range(0, 1)) = 1
        _SpecularHorizonStrength ("Specular Horizon Strength", Range(0, 1)) = 1
        [ToggleUI] _SceneLighting ("Tom Scene Lighting", Range(0, 1)) = 1
        _AreaLightIntensity ("Area Light Intensity", Range(0, 4)) = 1
        [Enum(Realtime,0,Reference,1)] _AreaLightQuality ("Area Light Quality", Range(0, 1)) = 0
        _EmissionColor ("Emission Color", Color) = (0, 0, 0, 1)
        _EmissionIntensity ("Emission Intensity", Range(0, 20)) = 1
        _Coverage ("Coverage", Range(0, 1)) = 1
        _Cutoff ("Coverage Cutoff", Range(0, 1)) = 0.5
        [ToggleUI] _AlphaClip ("Enable Coverage Cutoff", Range(0, 1)) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _CullOption ("Cull Mode", Range(0, 2)) = 2
        _ColorTextureMode ("Color Texture Input", Range(0, 2)) = 0
        _ColorValueMode ("Color Value Input", Range(0, 2)) = 0
        [ToggleUI] _DataTextureRestore ("Restore SRGB Material Data", Range(0, 1)) = 0
        _LightColorInput ("Unity Light Color Input", Range(0, 1)) = 0
        _ReflectionColorMode ("Probe Radiance Input", Range(0, 2)) = 0
        _DebugView ("Debug View", Range(0, 5)) = 0
        [HideInInspector][NonModifiableTextureData] _TomBSDFEnergyLUT ("TomBSDF Energy LUT v1", 2D) = "black" {}
        [HideInInspector][NonModifiableTextureData] _TomBSDFAnisoEnergyLUT ("TomBSDF Anisotropic Energy LUT v1", 3D) = "" {}
        [HideInInspector][NonModifiableTextureData] _TomBSDFRectLTC ("TomBSDF Rect LTC v1", 2D) = "black" {}
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" "IgnoreProjector"="True" "TomBSDFAreaVariants"="1" "ForceNoShadowCasting"="True" }
        LOD 400
        ZWrite Off
        ZTest LEqual
        Cull [_CullOption]
        Pass
        {
            Name "GlassTransmission"
            Tags { "LightMode"="Always" }
            Blend Zero SrcColor, One OneMinusSrcAlpha
            CGPROGRAM
            #pragma target 4.5
            #pragma only_renderers d3d11
            #pragma vertex TomGlassVertex
            #pragma fragment TomGlassFragment
            #define TOM_BSDF_ALPHA 1
            #define TOM_GLASS_TRANSMISSION_PASS 1
            #include "Passes/TomBSDFGlass.cginc"
            ENDCG
        }
        Pass
        {
            Name "ForwardBase"
            Tags { "LightMode"="ForwardBase" }
            Blend One One, Zero One
            ColorMask RGB
            CGPROGRAM
            #pragma target 4.5
            #pragma only_renderers d3d11
            #pragma vertex TomGlassVertex
            #pragma fragment TomGlassFragment
            #pragma multi_compile_fwdbase nolightmap nodirlightmap nodynlightmap
            #pragma multi_compile __ UNITY_SPECCUBE_BOX_PROJECTION
            #pragma multi_compile __ UNITY_SPECCUBE_BLENDING
            #pragma multi_compile_fog
            #pragma multi_compile_local __ TOM_BSDF_AREA_REALTIME TOM_BSDF_AREA_REFERENCE
            #define TOM_BSDF_ALPHA 1
            #include "Passes/TomBSDFGlass.cginc"
            ENDCG
        }
        Pass
        {
            Name "ForwardAdd"
            Tags { "LightMode"="ForwardAdd" }
            Blend One One, Zero One
            ColorMask RGB
            CGPROGRAM
            #pragma target 4.5
            #pragma only_renderers d3d11
            #pragma vertex TomGlassVertex
            #pragma fragment TomGlassFragment
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            #define TOM_BSDF_ALPHA 1
            #include "Passes/TomBSDFGlass.cginc"
            ENDCG
        }
    }
    Fallback Off
}
