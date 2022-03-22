Shader "Unlit/HealthBarShader"
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
                o.uv = v.uv;
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
                
                float t = saturate(InverseLerp(_ColorStart, _ColorEnd,_Health));
                float4 _ColorOut = lerp(_ColorA, _ColorB, t);
                    
                float HealthMask = (_Health > i.uv.x);
                _ColorOut = lerp(bgColor,_ColorOut, HealthMask);
                return _ColorOut;
                
                if(i.uv.x < _Health)
                    return _ColorOut;
                else
                    return 0;
            }
            ENDCG
        }
    }
}
