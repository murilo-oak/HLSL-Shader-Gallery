Shader "Unlit/DitheringBinary"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Gloss ("Gloss", Range(0,1)) = 1
        _DitherPattern ("Texture", 2D) = "" {}
        _DensityPattern("Density", Range(0.1, 1)) = 1
        
        _SurfaceColorA("Surface Color A", Color) = (1,1,1,1)
        _SurfaceColorB("Surface Color B", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" }
        
        Pass{
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "../Light/SharedFunctions.cginc"
            #include "AutoLight.cginc"
                        
            struct MeshData
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                float4 screenPosition : TEXCOORD1;
            };

            struct Interpolators
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float3 wPos : TEXCOORD2;
                float4 screenPosition: TEXCOORD3;
                LIGHTING_COORDS(3,4)
                            
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _DitherPattern;
            float4 _DitherPattern_ST;
            float _DensityPattern;
            
            Interpolators vert (MeshData v)
            {
                Interpolators o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                o.screenPosition = ComputeScreenPos(o.vertex);
                o.wPos = mul(UNITY_MATRIX_M, v.vertex);
                TRANSFER_VERTEX_TO_FRAGMENT(o); // lighting 

                float2 scaleCenter = float2(0.5f, 0.5f);
                o.uv = (v.uv - scaleCenter) * _DensityPattern + scaleCenter;
                
                //o.uv = TRANSFORM_TEX(v.uv, _DitherPattern);
                o.normal = UnityObjectToWorldNormal(v.normal);

                            
                return o;
            }
                        
            float _Gloss;
            float4 _SurfaceColorA;
            float4 _SurfaceColorB;
            
            float4 _DitherPattern_TexelSize;
            
            float4 frag (Interpolators i) : SV_Target
            {
                float3 normal = i.normal;
                float3 wPos = i.wPos;
                
                float2 screenPos = i.screenPosition.xy/i.screenPosition.w;
                float2 ditherCoordinate = screenPos * _ScreenParams.xy * _DitherPattern_TexelSize.xy;


                float2 scaleCenter = float2(0.5f, 0.5f);
                //(v.uv - scaleCenter) * _DensityPattern + scaleCenter;
                ditherCoordinate = (ditherCoordinate - scaleCenter) * _DensityPattern + scaleCenter;
                float ditherValue = tex2D(_DitherPattern, ditherCoordinate).r;
                
                float attenuation = LIGHT_ATTENUATION(i);
                const float4 whiteColor = float4(1,1,1,1);
                float3 light = ApplyLighting(whiteColor, normal, wPos, _Gloss, _LightColor0, attenuation);

                
                float ditherLight = step(ditherValue, light);
                float4 newColor = lerp(_SurfaceColorB, _SurfaceColorA, ditherLight);

                return newColor * 0.85;
                
            }
   
            ENDCG
        }
    }
}