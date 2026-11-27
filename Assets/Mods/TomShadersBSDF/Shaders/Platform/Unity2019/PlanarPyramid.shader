Shader "Hidden/TomPlanar/Pyramid" {
    Properties { [HideInInspector] _S2Cull ("Mirror sidedness", Float) = 2 }
    SubShader { Pass {
        Name "PlanarMip"
        Cull Off ZWrite Off ZTest Always
        CGPROGRAM
        #pragma only_renderers d3d11
        #pragma target 5.0
        #pragma vertex vert
        #pragma fragment frag
        Texture2D<float4> _PlanarInput;
        SamplerState tom_planar_linear_clamp_sampler;
        float4 _PlanarMipSizes;
        float _PlanarLevel;
        float4 vert(uint id:SV_VertexID):SV_POSITION {
            return float4(float2((id<<1)&2,id&2)*2-1,0,1);
        }
        float4 frag(float4 pos:SV_POSITION):SV_Target {
            float2 uv=pos.xy*_PlanarMipSizes.zw, d=.75*_PlanarMipSizes.xy;
            // Separable [1 3 3 1]/8 decimation. A single texel keeps its
            // centroid on either phase of a power-of-two mip grid.
            return .25*(_PlanarInput.SampleLevel(tom_planar_linear_clamp_sampler,uv-d,_PlanarLevel)
                +_PlanarInput.SampleLevel(tom_planar_linear_clamp_sampler,uv+d,_PlanarLevel)
                +_PlanarInput.SampleLevel(tom_planar_linear_clamp_sampler,uv+d*float2(1,-1),_PlanarLevel)
                +_PlanarInput.SampleLevel(tom_planar_linear_clamp_sampler,uv+d*float2(-1,1),_PlanarLevel));
        }
        ENDCG
    }
    Pass {
        Name "PlanarRangeSeed"
        Cull Off ZWrite Off ZTest Always
        CGPROGRAM
        #pragma only_renderers d3d11
        #pragma target 5.0
        #pragma vertex vert
        #pragma fragment frag
        #include "TomPlanarRange.cginc"
        Texture2D<float4> _PlanarSeedColor;
        Texture2D<float> _PlanarSeedDepth;
        float4 _PlanarSeedRange,_PlanarSeedEye,_PlanarSeedSize;
        float4x4 _PlanarSeedInverse;
        float4 vert(uint id:SV_VertexID):SV_POSITION {
            return float4(float2((id<<1)&2,id&2)*2-1,0,1);
        }
        float4 frag(float4 pos:SV_POSITION):SV_Target {
            int3 p=int3(pos.xy,0);
            float z=_PlanarSeedDepth.Load(p);
            float2 uv=pos.xy*_PlanarSeedSize.xy;
            float4 h=mul(_PlanarSeedInverse,float4(uv*float2(2,-2)+float2(-1,1),z,1));
            if(abs(h.w)<1e-7 || abs(z-_PlanarSeedSize.z)<=1e-7)return 0;
            float w=TomPlanarRangeWeight(distance(h.xyz/h.w,_PlanarSeedEye.xyz),_PlanarSeedRange);
            return float4(_PlanarSeedColor.Load(p).rgb*w,w);
        }
        ENDCG
    }
    Pass {
        Name "LayerSeed"
        Cull Off ZWrite Off ZTest Always
        CGPROGRAM
        #pragma only_renderers d3d11
        #pragma target 5.0
        #pragma vertex vert
        #pragma fragment frag
        Texture2D<float4> _S2RGB;
        float _S2Ranged;
        float4 vert(uint id:SV_VertexID):SV_POSITION {return float4(float2((id<<1)&2,id&2)*2-1,0,1);}
        float frag(float4 pos:SV_POSITION):SV_Target {return _S2Ranged>0?_S2RGB.Load(int3(pos.xy,0)).a:1;}
        ENDCG
    }
    Pass {
        Name "LayerOver"
        Cull [_S2Cull] ZWrite Off ZTest Always
        Blend SrcAlpha OneMinusSrcAlpha
        CGPROGRAM
        #pragma only_renderers d3d11
        #pragma target 5.0
        #pragma vertex vert
        #pragma fragment frag
        #include "TomPlanarLayer.cginc"
        ENDCG
    }
    Pass {
        Name "LayerAdd"
        Cull [_S2Cull] ZWrite Off ZTest Always
        Blend SrcAlpha One
        ColorMask 0 1
        CGPROGRAM
        #pragma only_renderers d3d11
        #pragma target 5.0
        #pragma vertex vert
        #pragma fragment frag
        #include "TomPlanarLayer.cginc"
        ENDCG
    }
    Pass {
        Name "LayerResolve"
        Cull Off ZWrite Off ZTest Always
        CGPROGRAM
        #pragma only_renderers d3d11
        #pragma target 5.0
        #pragma vertex vert
        #pragma fragment frag
        Texture2D<float4> _S2RGB;
        Texture2D<float> _S2Acceptance;
        float4 vert(uint id:SV_VertexID):SV_POSITION {return float4(float2((id<<1)&2,id&2)*2-1,0,1);}
        float4 frag(float4 pos:SV_POSITION):SV_Target {
            int3 p=int3(pos.xy,0);return float4(_S2RGB.Load(p).rgb,_S2Acceptance.Load(p));}
        ENDCG
    }
    Pass {
        Name "LayerGeometry"
        Cull [_S2Cull] ZWrite On ZTest LEqual ColorMask 0
        ColorMask 0 1
        CGPROGRAM
        #pragma only_renderers d3d11
        #pragma target 5.0
        #pragma vertex vert
        #pragma fragment frag
        #define TOM_PLANAR_LAYER_DEPTH 1
        #include "TomPlanarLayer.cginc"
        ENDCG
    }
    Pass {
        Name "LayerSupport"
        Cull Off ZWrite On ZTest Always ColorMask 0
        CGPROGRAM
        #pragma only_renderers d3d11
        #pragma target 5.0
        #pragma vertex vert
        #pragma fragment frag
        Texture2D<float4> _S2RGB;
        float _S2ClearZ;
        float4 vert(uint id:SV_VertexID):SV_POSITION {return float4(float2((id<<1)&2,id&2)*2-1,0,1);}
        float frag(float4 pos:SV_POSITION):SV_Depth {
            float4 c=_S2RGB.Load(int3(pos.xy,0));
            // No accepted radiance AND no accepted coverage. Black glass with
            // nonzero coverage and additive rain with zero coverage are both valid.
            if(any(c!=0))discard;
            return _S2ClearZ;
        }
        ENDCG
    } }
    Fallback Off
}
