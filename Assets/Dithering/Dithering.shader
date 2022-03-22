Shader "Unlit/Dithering"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1) 
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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 screenPosition : TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPosition = ComputeScreenPos(o.vertex);
                
                return o;
            }

            float4 _Color;

            float4 frag (v2f i) : SV_Target
            {
                // sample the texture
                float2 texCoordinate = i.screenPosition.xy/i.screenPosition.w;
                float aspect = _ScreenParams.x / _ScreenParams.y;
                
                texCoordinate.x = texCoordinate.x * aspect;
                texCoordinate = TRANSFORM_TEX(texCoordinate, _MainTex);

                float4 col = tex2D(_MainTex, texCoordinate);

                col *= _Color;
                return col;
            }
            ENDCG
        }
    }
}
