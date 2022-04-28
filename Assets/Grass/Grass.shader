Shader "Unlit/Grass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        _ColorTop ("Color Top", Color) = (1,1,1,1)
        _ColorBottom ("Color Bottom", Color) = (0,0,0,1)
        
        _RandomBendRotation ("Random Bend", Range(0,1)) = 0.1
        
        _Hight ("Height", Range(0,2)) = 1
        _Width ( "Width", Range(0,2)) = 1
        
        _TessellationUniform("Tessellation Uniform", Range(1, 64)) = 1
        
        
        _WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
        _WindFrequency("Wind Frequency", Vector) = (0.05, 0.05, 0, 0)
        _WindStrength("Wind Strength", Float) = 1
    }
    CGINCLUDE

    #define BLADES_COUNT 3
    
    struct geometryOutput
    {
        float4 pos : SV_POSITION;
        float2 uv : TEXCOORD0;
    };

    float3x3 BuildAxisAngleRotation3x3(float angle, float3 axis)
    {
        float s, c;
        sincos(angle, s, c);

        float x = axis.x;
        float y = axis.y;
        float z = axis.z;
        
        float cComplement = 1 - c;
        

        //rotation matrix math
        return float3x3 (
            c + cComplement * x * x    , cComplement * x * y - s * z, cComplement * x * z + s * y,
            cComplement * x * y + s * z, c + cComplement * y * y    , cComplement * y * z - s * x,
            cComplement * x * z - s * y, cComplement * y * z + s * x, c + cComplement * z * z
        );
    }

    float rand(float3 co)
	{
		return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
	}
    
    ENDCG
    
    
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma geometry geo
            #pragma fragment frag
            #pragma hull hull
            #pragma domain domain

            #define TAU 6.28318530718

            #include "UnityCG.cginc"
            #include "CustomTessellation.cginc"

            // struct appdata
            // {
            //     float4 vertex : POSITION;
            //     float2 uv : TEXCOORD0;
            //     float3 normal : NORMAL;
            //     float4 tangent : TANGENT;
            // };
            //
            // struct v2f
            // {
            //     float4 vertex : SV_POSITION;
            //     float3 normal : NORMAL;
            //     float4 tangent : TANGENT;
            //     float2 uv : TEXCOORD0;
            // };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _ColorTop;
            float4 _ColorBottom;
            float _RandomBendRotation;
            float _Width;
            float _Hight;

            sampler2D _WindDistortionMap;
            float4 _WindDistortionMap_ST;

            float2 _WindFrequency;
            float _WindStrength;

            // v2f vert (appdata v)
            // {
            //     v2f o;
            //     o.vertex = v.vertex;
            //     o.normal = v.normal;
            //     o.tangent = v.tangent;
            //     o.uv = v.uv;
            //     return o;
            // }
            
            [maxvertexcount(BLADES_COUNT * 2 + 1)]
            void geo(triangle vertexOutput IN[3] : SV_POSITION, inout TriangleStream<geometryOutput> triStream)
            {
                geometryOutput o;
                float3 pos = IN[0].vertex;
                float3 normal = IN[0].normal;
                float4 tangent = IN[0].tangent;
                float3 biTangent = cross(normal, tangent.xyz) * tangent.w;

                float2 uv = pos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y;
                float2 windSample = (tex2Dlod(_WindDistortionMap, float4(uv, 0, 0)).xy * 2 - 1) * _WindStrength;
                float3 wind = normalize(float3(windSample.x, windSample.y, 0));
                float3x3 windRotation = BuildAxisAngleRotation3x3(UNITY_PI * windSample, wind);

                float3x3 tangentToLocal = float3x3(
                    tangent.x, biTangent.x, normal.x,
                    tangent.y, biTangent.y, normal.y,
                    tangent.z, biTangent.z, normal.z
                );
                
                float3x3 rotationAngleAxisMatrix = BuildAxisAngleRotation3x3(rand(pos) * TAU, normal);
                float3x3 bendRotationMatrix = BuildAxisAngleRotation3x3(rand(pos.xzz) * TAU * 0.25 * _RandomBendRotation, float3(1,0,0));
                float3x3 facingMatrix = mul(mul(bendRotationMatrix, rotationAngleAxisMatrix), tangentToLocal); 
                float3x3 transformMatrix = mul(facingMatrix , windRotation);


                float3 width = float3(0.5, 0, 0) * _Width * (rand(pos.xzy) * 0.5 + 0.5);
                float3 hight = float3(0, 0, 1) * _Hight * (rand(pos) * 0.6 + 0.4);
                
                o.pos = UnityObjectToClipPos(mul(facingMatrix, width) + pos);
                o.uv = float2(1,0);
                triStream.Append(o);
            
                o.pos = UnityObjectToClipPos(mul(facingMatrix, -width) + pos);
                o.uv = float2(0,0);
                triStream.Append(o);
            
                o.pos = UnityObjectToClipPos(mul(transformMatrix, hight) + pos);
                o.uv = float2(0.5,1);
                triStream.Append(o);
            }

            fixed4 frag (geometryOutput i) : SV_Target
            {
                float4 color = lerp(_ColorBottom, _ColorTop, i.uv.y);
                return color;
            }
            ENDCG
        }
    }
}
