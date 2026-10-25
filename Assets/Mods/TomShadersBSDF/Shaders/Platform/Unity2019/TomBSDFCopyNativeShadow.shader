Shader "Hidden/TomBSDF/CopyNativeShadow"
{
    SubShader
    {
        Cull Off ZWrite Off ZTest Always
        CGINCLUDE
        #pragma target 5.0
        #include "UnityCG.cginc"
        #include "Lighting.cginc"
        float4 _TomNativeCaptureInfo, _TomNativeCaptureSettings, _TomNativeCaptureDestination;
        float4 _TomNativeCaptureScope;
        float _TomNativeCopyOwner, _TomNativeCopySlot;
        Texture2D<float> _TomNativeShadow2D;
        TextureCube<float> _TomNativeShadowCube;
        Texture2D<float> _TomNativeCopyStamp;
        struct VertexOutput { float4 pos : SV_POSITION; float2 uv : TEXCOORD0; };
        VertexOutput Vertex(uint id : SV_VertexID)
        {
            VertexOutput o;
            o.uv = float2((id << 1) & 2, id & 2);
            o.pos = float4(o.uv * 2.0 - 1.0, 0, 1);
            if (abs(_TomNativeCopyOwner) > .5 && _TomNativeCopyOwner != _TomNativeCaptureScope.x) o.pos = float4(2,2,2,1);
            #if UNITY_UV_STARTS_AT_TOP
                o.uv.y = 1.0 - o.uv.y;
            #endif
            return o;
        }
        float4 Metadata(VertexOutput i) : SV_Target
        {
            uint index = (uint)i.pos.x;
            if (_TomNativeCaptureInfo.z == 1 && index < 4)
            {
                // The caster VP is current here; unity_WorldToShadow can still
                // describe the previous light. D3D shadow textures use top-left UV.
                if (index == 0) return .5 * (UNITY_MATRIX_VP[0] + UNITY_MATRIX_VP[3]);
                if (index == 1) return .5 * (-UNITY_MATRIX_VP[1] + UNITY_MATRIX_VP[3]);
                return UNITY_MATRIX_VP[index];
            }
            if (index < 16) return unity_WorldToShadow[index / 4][index % 4];
            if (index < 20) return unity_ShadowSplitSpheres[index - 16];
            if (index == 20) return unity_ShadowSplitSqRadii;
            if (index == 21) return _LightShadowData;
            if (index == 22) return _LightProjectionParams;
            if (index == 23) return _LightPositionRange;
            if (index == 24) return unity_ShadowFadeCenterAndType;
            if (index == 25) return _WorldSpaceLightPos0;
            if (index == 26)
            {
                uint width, height, levels;
                if (_TomNativeCaptureInfo.z > 1.5) _TomNativeShadowCube.GetDimensions(0, width, height, levels);
                else _TomNativeShadow2D.GetDimensions(0, width, height, levels);
                return float4(width, height, 1.0 / max(width, 1), 1.0 / max(height, 1));
            }
            if (index == 27) return _LightSplitsNear;
            if (index == 28) return _LightSplitsFar;
            if (index == 29) return unity_LightShadowBias;
            if (index == 30)
            {
                float4 value = _TomNativeCaptureSettings;
                if (_TomNativeCaptureInfo.y == 0) { value.x = _TomNativeCaptureScope.z; value.w = _TomNativeCaptureScope.w; }
                return value;
            }
            if (index == 31)
            {
                // Directional matrices are not current until the screen-mask
                // event. The early map copy must not advertise a valid packet.
                if (_TomNativeCaptureInfo.y == 0 && _TomNativeCaptureInfo.z == 0) return 0;
                return float4(_TomNativeCaptureInfo.x, _TomNativeCaptureInfo.y == 0 ? _TomNativeCaptureScope.y : _TomNativeCaptureInfo.y,
                    _TomNativeCaptureInfo.z, _TomNativeCopySlot);
            }
            if (index == 32) return _LightColor0;
            if (index == 33) return _TomNativeCaptureDestination;
            if (index == 34) return float4(_WorldSpaceCameraPos, 1);
            if (index == 35) return _ProjectionParams;
            if (index >= 36) return UNITY_MATRIX_VP[index - 36];
            return 0;
        }
        float4 DirectionalMetadata(VertexOutput i) : SV_Target
        {
            uint index = (uint)i.pos.x;
            if (index == 31)
            {
                float stamp = _TomNativeCopyStamp.Load(int3(0, (uint)_TomNativeCopySlot, 0));
                return stamp == _TomNativeCaptureScope.y ? float4(1, stamp, 0, _TomNativeCopySlot) : 0;
            }
            if (index < 22 || index == 24 || index == 27 || index == 28 || index == 29) return Metadata(i);
            discard;
            return 0;
        }
        float4 DepthStamp(VertexOutput i) : SV_Target { return _TomNativeCaptureScope.y.xxxx; }
        SamplerState tom_native_point_clamp_sampler;
        float4 Copy2D(VertexOutput i) : SV_Target
        {
            return _TomNativeShadow2D.SampleLevel(tom_native_point_clamp_sampler, i.uv, 0).xxxx;
        }
        float3 CubeDirection(float2 uv, uint face)
        {
            float2 p = uv * 2.0 - 1.0;
            if (face == 0) return float3(1, -p.y, -p.x);
            if (face == 1) return float3(-1, -p.y, p.x);
            if (face == 2) return float3(p.x, 1, p.y);
            if (face == 3) return float3(p.x, -1, -p.y);
            if (face == 4) return float3(p.x, -p.y, 1);
            return float3(-p.x, -p.y, -1);
        }
        float4 CopyCube(VertexOutput i) : SV_Target
        {
            float2 tile = i.uv * float2(3, 2);
            uint face = (uint)tile.x + 3 * (uint)tile.y;
            return _TomNativeShadowCube.SampleLevel(tom_native_point_clamp_sampler, CubeDirection(frac(tile), face), 0).xxxx;
        }
        ENDCG
        Pass
        {
            Name "Metadata"
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Metadata
            ENDCG
        }
        Pass
        {
            Name "Depth2D"
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment Copy2D
            ENDCG
        }
        Pass
        {
            Name "DepthCube"
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment CopyCube
            ENDCG
        }
        Pass
        {
            Name "DirectionalMetadata"
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment DirectionalMetadata
            ENDCG
        }
        Pass
        {
            Name "DepthStamp"
            CGPROGRAM
            #pragma vertex Vertex
            #pragma fragment DepthStamp
            ENDCG
        }
    }
    Fallback Off
}
