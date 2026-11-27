#include "UnityCG.cginc"
#include "TomPlanarRange.cginc"
sampler2D _S2Main,_S2Mask,_S2Emission;
sampler2D _S2Thickness,_S2Roughness;
samplerCUBE _S2Probe;
Texture2D<float> _S2Opaque;
Texture2D<float4> _S2Black,_S2White;
Texture2D<float4> _S2Backdrop;
float4 _S2Thickness_ST,_S2Roughness_ST;
float _S2Cutoff;
float4 _S2Main_ST,_S2Mask_ST,_S2Emission_ST,_S2Tint,_S2Glow,_S2Range,_S2Eye,_S2Size,_S2Optics,_S2Absorb,_S2Decode,_S2Data;
float4x4 _S2Inverse;
struct vIn {float4 vertex:POSITION;float3 normal:NORMAL;float4 color:COLOR;float2 uv:TEXCOORD0;};
struct vary {float4 pos:SV_POSITION;float3 world:TEXCOORD0;float3 normal:TEXCOORD1;float2 uv:TEXCOORD2;float4 color:COLOR;};
vary vert(vIn v){
    vary o;o.pos=UnityObjectToClipPos(v.vertex);o.world=mul(unity_ObjectToWorld,v.vertex).xyz;
    o.normal=UnityObjectToWorldNormal(v.normal);o.uv=v.uv;o.color=v.color;return o;
}
struct output {float4 color:SV_Target0;float4 confidence:SV_Target1;};
output frag(vary i) {
    float z=_S2Opaque.Load(int3(i.pos.xy,0));
    float3 v=_S2Eye.xyz-i.world;float d=length(v);
    float soft=1;
    if(abs(z-_S2Size.z)>1e-7){
        float2 uv=i.pos.xy*_S2Size.xy;
        float4 h=mul(_S2Inverse,float4(uv*float2(2,-2)+float2(-1,1),z,1));
        if(abs(h.w)>1e-7){
            float gap=distance(h.xyz/h.w,_S2Eye.xyz)-d;
            clip(gap+0.0001);if(_S2Data.y>0)soft=saturate(gap*_S2Data.y);
        }
    }
    float w=TomPlanarRangeWeight(d,_S2Range);
    float4 base=tex2D(_S2Main,i.uv*_S2Main_ST.xy+_S2Main_ST.zw)*_S2Tint;
    if(_S2Data.z>0)base*=i.color;
    float a=saturate(base.a*tex2D(_S2Mask,i.uv*_S2Mask_ST.xy+_S2Mask_ST.zw).r*_S2Data.x)*soft;
    if(_S2Cutoff>0 && _S2Data.w==0)clip(a-_S2Cutoff);
    float3 glow=tex2D(_S2Emission,i.uv*_S2Emission_ST.xy+_S2Emission_ST.zw).rgb*_S2Glow.rgb;
    float3 rgb=base.rgb+glow;
    if(_S2Data.w>0){
        // The native color pass was evaluated on black and white. Recover its
        // over coefficient independently of the material's alpha-channel blend.
        int3 pixel=int3(i.pos.xy,0);
        float3 black=_S2Black.Load(pixel).rgb,white=_S2White.Load(pixel).rgb;
        a=saturate(1-dot(white-black,float3(.3333333,.3333333,.3333333)));
        rgb=black/max(1e-6,a);
    }
    if(_S2Optics.x>0){
        float3 n=normalize(i.normal);v/=max(d,1e-6);
        float nv=saturate(abs(dot(n,v))), f0=(_S2Optics.x-1)/(_S2Optics.x+1);
        float f=lerp(f0*f0,1,pow(1-nv,5));
        float rough=saturate(_S2Optics.y*tex2D(_S2Roughness,i.uv*_S2Roughness_ST.xy+_S2Roughness_ST.zw).r);
        float3 env=DecodeHDR(texCUBElod(_S2Probe,float4(reflect(-v,n),rough*(1.7-.7*rough)*6)),_S2Decode)*_S2Optics.w;
        float thickness=_S2Optics.z*tex2D(_S2Thickness,i.uv*_S2Thickness_ST.xy+_S2Thickness_ST.zw).r;
        float3 transmit=(1-f)*pow(max(.0001,saturate(base.rgb*_S2Absorb.rgb)),thickness/max(.15,nv));
        // Transmit the already sorted mirror layers, never the parent's scene snapshot.
        float3 behind=_S2Backdrop.Load(int3(i.pos.xy,0)).rgb;
        float t=min(transmit.x,min(transmit.y,transmit.z));rgb=(env*f+behind*(transmit-t)+glow)/max(.0001,1-t);
        a*=1-t;
    }
    #ifdef TOM_PLANAR_LAYER_DEPTH
    clip(w*a-1e-6);
    #endif
    output o;o.color=float4(w*rgb,a);o.confidence=float4(w,0,0,a);return o;
}
