Shader "tom/RectAreaLight"
{
    Properties
    {
        [ToggleUI] _AreaLightEnabled ("Area Light Enabled", Range(0, 1)) = 1
        _AreaLightColor ("Emitter Color", Color) = (1, 1, 1, 1)
        _AreaLightRadiance ("Linear Radiance", Range(0, 100)) = 1
        _AreaLightWidth ("Width (World Units)", Range(0.001, 10)) = 1
        _AreaLightHeight ("Height (World Units)", Range(0.001, 10)) = 1
        [ToggleUI] _AreaLightTwoSided ("Two Sided Emitter", Range(0, 1)) = 0
        _AreaLightPriority ("Selection Priority", Range(-10, 10)) = 0
        [Enum(SRGB,0,Linear,1)] _AreaLightColorInput ("Emitter Color Input", Range(0, 1)) = 0
        [HideInInspector] _TomRectAreaLightControl ("Control Contract", Float) = 1
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        Pass
        {
            ColorMask 0
            ZWrite Off
            Cull Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            float4 vert(float4 position : POSITION) : SV_POSITION { return UnityObjectToClipPos(position); }
            float4 frag() : SV_Target { discard; return 0; }
            ENDCG
        }
    }
    Fallback Off
}
