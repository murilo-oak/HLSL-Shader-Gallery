Shader "Unlit/Grass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        _ColorTop ("Color Top", Color) = (1,1,1,1)
        _ColorBottom ("Color Bottom", Color) = (0,0,0,1)
        
        _RandomBendRotation ("Random Bend", Range(0,1)) = 0.1
        
        _Height ("Height", Range(0,2)) = 1
        _BladeHeightRandom ("Height Random", Range(0,2)) = 0.3 
        
        _Width ( "Width", Range(0,2)) = 1
        _BladeWidthRandom("Blade Width Random", Float) = 0.02
        
        _TessellationUniform("Tessellation Uniform", Range(1, 64)) = 1
        
        
        _WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
        _WindFrequency("Wind Frequency", Vector) = (0.05, 0.05, 0, 0)
        _WindStrength("Wind Strength", Float) = 1
        
        
        _BladeForward("Blade Forward Amount", Float) = 0.38
        _BladeCurve("Blade Curvature Amount", Range(1, 4)) = 2
    }
    CGINCLUDE

    #define BLADE_SEGMENTS 10
    #include "CustomTessellation.cginc"
    #include  "AutoLight.cginc"
    #include "UnityCG.cginc"
    #include "UnityLightingCommon.cginc"
    
    struct geometryOutput
    {
        float4 pos : SV_POSITION;
    	float3 normal : NORMAL;
        float2 uv : TEXCOORD0;
    	unityShadowCoord4 _ShadowCoord : TEXCOORD1;
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

    geometryOutput VertexOutput(float3 pos, float3 normal, float2 uv)
    {
	    geometryOutput o;
	    o.pos = UnityObjectToClipPos(pos);
		o.normal = UnityObjectToWorldNormal(normal);
    	o.uv = uv;
    	
    	o._ShadowCoord = ComputeScreenPos(o.pos);
	    return o;
    }
    
    geometryOutput GenerateGrassVertex(float3 vertexPosition, float width, float foward, float height, float2 uv, float3x3 transformMatrix)
    {
	    float3 tangentPoint = float3(width, height, foward);
    	float3 tangentNormal = float3(0, -1, 0);
		float3 localNormal = mul(transformMatrix, tangentNormal);

	    float3 localPosition = vertexPosition + mul(tangentPoint, transformMatrix);
	    return VertexOutput(localPosition, localNormal, uv);
    }
    
    ENDCG
    
    
    SubShader
    {
	    Tags { "LightMode" = "ForwardBase" }
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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _ColorTop;
            float4 _ColorBottom;
            float _RandomBendRotation;

            
            float _Height;
            float _BladeHeightRandom;	

            float _Width;
            float _BladeWidthRandom;

            sampler2D _WindDistortionMap;
            float4 _WindDistortionMap_ST;

            float2 _WindFrequency;
            float _WindStrength;

            float _BladeForward;
            float _BladeCurve;
            
            
            [maxvertexcount(BLADE_SEGMENTS * 2 + 1)]
            void geo (triangle vertexOutput IN[3] : SV_POSITION, inout TriangleStream<geometryOutput> triStream)
            {
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
                float3x3 bendRotationMatrix = BuildAxisAngleRotation3x3(rand(pos.zzx) * TAU * 0.5 * _RandomBendRotation, float3(1,0,0));
                float3x3 facingMatrix = mul(mul(tangentToLocal, bendRotationMatrix), rotationAngleAxisMatrix); 
                float3x3 transformMatrix = mul(facingMatrix , windRotation);


                float3 width = float3(0.5, 0, 0) * _Width * (rand(pos.xzy) * 0.5 + 0.5);
                float forward = rand(pos.yyz) * _BladeForward;
                float height = (rand(pos.zyx) * 2 - 1) * _BladeHeightRandom + _Height;

                for (int i = 0; i < BLADE_SEGMENTS; i++)
                {
	                float t = i / (float)BLADE_SEGMENTS;

                    float segmentHeight = height * t;
                    float segmentWidth = width * (1 - t);
                    float segmentForward = pow(t, _BladeCurve) * forward;

                	float3x3 transformMatrix2;
                	
					if(i!=0)
                	{
                		windRotation = BuildAxisAngleRotation3x3(UNITY_PI * windSample, wind * t);
                		transformMatrix2 = mul(facingMatrix , windRotation);
                	}else
                	{
                		transformMatrix2 = facingMatrix;
                	}
                    

                    triStream.Append(GenerateGrassVertex(pos, segmentWidth, segmentForward, segmentHeight, float2(0, t), transformMatrix2));
                    triStream.Append(GenerateGrassVertex(pos, -segmentWidth, segmentForward, segmentHeight, float2(1, t), transformMatrix2));
                }
                
                triStream.Append(GenerateGrassVertex(pos, 0, forward, height, float2(0.5, 1), transformMatrix));
                
            }

            fixed4 frag (geometryOutput i) : SV_Target
            {
                float4 color = lerp(_ColorBottom, _ColorTop, i.uv.y);
				half shadow = SHADOW_ATTENUATION(i);
				
				float NdotL = saturate(saturate(dot(i.normal, _WorldSpaceLightPos0))) * shadow;

				float3 ambientLight = ShadeSH9(float4(i.normal, 1));
				float4 lightIntensity = 0.2 + NdotL * _LightColor0 + float4(ambientLight, 1);
				float4 col = lerp(_ColorBottom, _ColorTop * lightIntensity, i.uv.y);

				return col;
            }
            ENDCG
        }
        Pass
		{
			Tags { "LightMode" = "ShadowCaster" }

			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag
			#pragma hull hull
			#pragma domain domain
			#pragma target 4.6
			#pragma multi_compile_shadowcaster

			float4 frag(geometryOutput i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i);
			}

			ENDCG
		}
    }
}
