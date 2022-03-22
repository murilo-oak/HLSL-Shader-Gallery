Shader "Unlit/SurfaceDithering" {
	Properties {
		_Color ("Tint", Color) = (0, 0, 0, 1)
		_MainTex ("Texture", 2D) = "white" {}
		_Smoothness ("Smoothness", Range(0, 1)) = 0
		_Metallic ("Metalness", Range(0, 1)) = 0
		[HDR] _Emission ("Emission", color) = (0,0,0)
		
		_DitherPattern ("Dithering Pattern", 2D) = "white" {}
	}
	SubShader {
		Tags{ "RenderType"="Opaque" "Queue"="Geometry"}

		CGPROGRAM

		#pragma surface surf Standard fullforwardshadows
		#pragma target 3.0
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		fixed4 _Color;

		half _Smoothness;
		half _Metallic;
		half3 _Emission;

		struct Input {
			float2 uv_MainTex;
			float4 screenPos;
		};

		//float4 _MainTex_ST;
		sampler2D _DitherPattern;
		float4 _DitherPattern_TexelSize;

		struct v2f
		{
			float4 position : SV_POSITION;
			float2 uv : TEXCOORD0;
			float4 screenPosition : TEXCOORD1;
		};

		fixed4 frag(v2f i) : SV_TARGET{

			float texColor = tex2D(_MainTex, i.uv).r;
			
			//value from the dither pattern
		    float2 screenPos = i.screenPosition.xy / i.screenPosition.w;
		    float2 ditherCoordinate = screenPos * _ScreenParams.xy * _DitherPattern_TexelSize.xy;
		    float ditherValue = tex2D(_DitherPattern, ditherCoordinate).r;

		    //combine dither pattern with texture value to get final result
		    float col = step(ditherValue, texColor);
		    return col;
			
		}

		void surf (Input i, inout SurfaceOutputStandard o) {
			//texture value the dithering is based on
		    float texColor = tex2D(_MainTex, i.uv_MainTex).r;

		    //value from the dither pattern
		    //float2 screenPos = i.screenPos.xy / i.screenPos.w;
		    float2 screenPos = i.screenPos.xy / i.screenPos.w;
		    float2 ditherCoordinate = screenPos * _ScreenParams.xy * _DitherPattern_TexelSize.xy;
		    float ditherValue = tex2D(_DitherPattern, ditherCoordinate).r;

			float ditheredValue = step(ditherValue, texColor);
			//col *= _Color;
			o.Albedo = ditheredValue;
			o.Metallic = _Metallic;
			o.Smoothness = _Smoothness;
			o.Emission = _Emission;
		}
		ENDCG
	}
	FallBack "Standard"
}