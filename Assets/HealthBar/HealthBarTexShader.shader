Shader "Unlit/HealthBarTexShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Health ("Health", Range(0,1)) = 1
        
        _ColorStart ("Color Start", Range(0,1)) = 1 
        _ColorEnd ("Color End", Range(0,1)) = 0 
        
        _ColorA ("Color A", Color) = (1,1,1,1)
        _ColorB ("Color B", Color) = (1,1,1,1)
        
    }
    SubShader
    {
        Tags { 
            "RenderType"="Transparent" 
            "Queue" = "Transparent"    
            }
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #define TAU 6.28318530718

            struct MeshData
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Interpolators
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float4 _ColorA;
            float4 _ColorB;

            float _Health; 

            float _ColorStart;
            float _ColorEnd;

            float InverseLerp(float a, float b, float v)
            {
                return (v-a)/(b-a);
            }

            float4 frag (Interpolators i) : SV_Target
            {
                float4 bgColor = float4(0,0,0,0);   

                float t = cos((_Time.y - TAU/4) * 3.0) * 0.1 +1;
                
                float2 tex = float2(_Health, i.uv.y);
                float4 texColor = tex2D(_MainTex , tex);

                float HealthMask = (_Health > i.uv.x);

                if(_Health<=0.2) {
                    texColor *= t;
                }
                texColor = lerp(bgColor,texColor, HealthMask);
                return texColor;
            }
            ENDCG
        }
    }
}
