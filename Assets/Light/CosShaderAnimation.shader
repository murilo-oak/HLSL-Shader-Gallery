Shader "Unlit/CosShaderAnimation"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _ColorA ("Color A", Color) = (1,1,1,1)
        _ColorB ("Color B", Color) = (1,1,1,1)
        
        _ColorStart ("Color Start", Range(0,1)) = 1 
        _ColorEnd ("Color End", Range(0,1)) = 0 
        _WaveSpeed("Wave Speed", Range(0,4)) = 1 
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #define TAU 6.28318530718

            struct MeshData
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _ColorA;
            float4 _ColorB;
            
            float4 _ColorOut;
            float4 _MainTex_ST;

            float _ColorStart;
            float _ColorEnd;
            float _WaveSpeed;

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                
                //o.vertex = v.vertex;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.normal = v.normal;
                return o;
            }

            float InverseLerp(float a, float b, float v)
            {
                return (v-a)/(b-a);
            }
            
            float4 frag (Interpolators i) : SV_Target
            {

                float xOffset = cos(i.uv.y * TAU * 8) * 0.01 + _Time.y * _WaveSpeed;
                float t = cos((i.uv.x+ xOffset) * TAU * 5) * 0.5 + 0.5;
                
                _ColorOut = frac(lerp(_ColorA, _ColorB, saturate(t)));
                return _ColorOut;
            }
            ENDCG
        }
    }
}
