Shader "Hidden/TomBSDF/CopySceneDepth"
{
    SubShader
    {
        Pass
        {
            ZTest Always
            ZWrite Off
            Cull Off
            CGPROGRAM
            #pragma target 4.5
            #pragma vertex vert_img
            #pragma fragment frag
            #include "UnityCG.cginc"
            UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
            float frag(v2f_img i) : SV_Target { return SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv); }
            ENDCG
        }
    }
    Fallback Off
}
