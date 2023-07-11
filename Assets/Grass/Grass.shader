Shader "Unlit/Grass"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        _ColorTop ("Color Top", Color) = (1,1,1,1)
        _ColorBottom ("Color Bottom", Color) = (0,0,0,1)
    	_ScatteringColor ("Color Scattering", Color) = (0,0,0,1)
        
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
    	
    	_Scale("SSS Scale", Range(0, 1)) = 0
    	_Distortion("SSS Distortion", Range(0,1)) = 0
    	_Power("SSS Power", Float) = 0
    }
    CGINCLUDE

    #define BLADE_SEGMENTS 10
    #include "CustomTessellation.cginc"
    #include  "AutoLight.cginc"
    #include "UnityCG.cginc"
    #include "UnityLightingCommon.cginc"

	float _Scale;
    float _Power;
    float _Distortion;
    float4 _ScatteringColor;
    
    struct geometryOutput
    {
        float4 pos : SV_POSITION;
    	float3 normal : NORMAL;
        float2 uv : TEXCOORD0;
		float3 vertexWorld : TEXCOORD1;
    };

    float3x3 BuildAxisAngleRotation3x3(float angle, float3 axis)
    {
        float s, c;
        sincos(angle, s, c);

        float x = axis.x;
        float y = axis.y;
        float z = axis.z;
        
        float cComplement = 1 - c;
        

        // Rotation matrix math
        return float3x3 (
            c + cComplement * x * x    , cComplement * x * y - s * z, cComplement * x * z + s * y,
            cComplement * x * y + s * z, c + cComplement * y * y    , cComplement * y * z - s * x,
            cComplement * x * z - s * y, cComplement * y * z + s * x, c + cComplement * z * z
        );
    }

    float rand(float3 co)
	{
    	// Seed
		return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
	}

    inline half4 SubsurfaceScatering(half3 viewDir, half3 normal)
            {
    			float3 lightDir = _WorldSpaceLightPos0;
                float3 normalN = normalize(normal);
    	
                float3 halfVecN = normalize(lightDir + normalN * _Distortion);
				float3 viewDirN = normalize(viewDir);

    			// SSS
    			float  intensity = pow(saturate(dot(viewDirN, -halfVecN)), _Power) * _Scale;
                return intensity * _LightColor0 * _ScatteringColor;
            }

    geometryOutput VertexOutput(float3 pos, float3 normal, float2 uv)
    {
	    geometryOutput o;

    	o.pos = UnityObjectToClipPos(pos);
		o.normal = UnityObjectToWorldNormal(normal);
    	o.uv = uv;
    	o.vertexWorld = mul(unity_ObjectToWorld, float4(pos, 1)).xyz;
    	
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

            	// Get uv offset and tiling coordinate
                float2 uv = pos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y;

            	// Get from noise texture the wind sample
            	float2 windSample = (tex2Dlod(_WindDistortionMap, float4(uv, 0, 0)).xy * 2 - 1) * _WindStrength;

            	// Normalize wind sample
            	float3 wind = normalize(float3(windSample.x, windSample.y, 0));

				// The rotation that will be applied to the grass by the wind
            	float3x3 windRotation = BuildAxisAngleRotation3x3(UNITY_PI * windSample, wind);

            	// Build matrix that transform tangent space vectors to local space
                float3x3 localSpaceMatrix = float3x3(
                    tangent.x, biTangent.x, normal.x,
                    tangent.y, biTangent.y, normal.y,
                    tangent.z, biTangent.z, normal.z
                );

            	// Build rotation matrix around normal, the amount of grass' rotation is defined by a seed
                float3x3 rotationAngleAxisMatrix = BuildAxisAngleRotation3x3(rand(pos) * TAU, normal);

            	// Build rotation to define the bend of the grass
                float3x3 bendRotationMatrix = BuildAxisAngleRotation3x3(rand(pos.zzx) * TAU * 0.5 * _RandomBendRotation, float3(1,0,0));

				// Build rotation that define where the grass is facing
            	float3x3 facingMatrix = mul(mul(localSpaceMatrix, bendRotationMatrix), rotationAngleAxisMatrix); 

				// Final rotation that define where the grass is facing with wind rotation
            	float3x3 transformMatrix = mul(facingMatrix , windRotation);


            	// Setup blade parameters
                float3 width = float3(0.5, 0, 0) * _Width * (rand(pos.xzy) * 0.5 + 0.5);
                float forward = rand(pos.yyz) * _BladeForward;
                float height = (rand(pos.zyx) * 2 - 1) * _BladeHeightRandom + _Height;

            	// Construct blade
                for (int i = 0; i < BLADE_SEGMENTS; i++)
                {
                	// Interpolator to be used to position the vertex of the blade
	                float grassProgress = i / (float)BLADE_SEGMENTS;

                	// Define the segment blade parameters
                    float segmentHeight = height * grassProgress;
                    float segmentWidth = width * (1 - grassProgress);
                    float segmentForward = pow(grassProgress, _BladeCurve) * forward;

                	float3x3 transformMatrixAlongBlade;
                	
					if(i!=0)
                	{
						// GrassProgress can be used as a weight of wind rotation, because the bottom receives less
						// effect from the wind than the top
                		windRotation = BuildAxisAngleRotation3x3(UNITY_PI * windSample, wind * grassProgress);
                		transformMatrixAlongBlade = mul(facingMatrix , windRotation);
                	}else
                	{
                		// Bottom of the blade is not affected by wind, it is stuck on the ground's surface
                		transformMatrixAlongBlade = facingMatrix;
                	}
                    
					// Right and left blade position
                    triStream.Append(GenerateGrassVertex(pos, segmentWidth, segmentForward, segmentHeight, float2(0, grassProgress), transformMatrixAlongBlade));
                    triStream.Append(GenerateGrassVertex(pos, -segmentWidth, segmentForward, segmentHeight, float2(1, grassProgress), transformMatrixAlongBlade));
                }

            	// Final/top blade position 
                triStream.Append(GenerateGrassVertex(pos, 0, forward, height, float2(0.5, 1), transformMatrix));
                
            }

            fixed4 frag (geometryOutput i) : SV_Target
            {
            	// Grass color
                float4 color = lerp(_ColorBottom, _ColorTop, i.uv.y);
				
            	float3 viewDirection  = normalize(_WorldSpaceCameraPos - i.vertexWorld );
				float geometryFactorClampled = clamp(dot(_WorldSpaceLightPos0, i.normal), 0.9, 1);
				float4 SSS = SubsurfaceScatering( viewDirection, i.normal);
            	//final color
				float4 finalColor =  geometryFactorClampled * (color + SSS);

            	return finalColor;
            }
            ENDCG
        }
    }
}
