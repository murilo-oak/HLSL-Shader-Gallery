#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc"
#include "SharedFunctions.cginc"
#include "AutoLight.cginc"
            
struct MeshData
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;
};

struct Interpolators
{
    float2 uv : TEXCOORD0;
    float4 vertex : SV_POSITION;
    float3 normal : TEXCOORD1;
    float3 wPos : TEXCOORD2;
    LIGHTING_COORDS(3,4)
                
};

sampler2D _MainTex;
float4 _MainTex_ST;

Interpolators vert (MeshData v)
{
    Interpolators o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.wPos = mul(UNITY_MATRIX_M, v.vertex);
    TRANSFER_VERTEX_TO_FRAGMENT(o); // lighting 

    o.uv = TRANSFORM_TEX(v.uv, _MainTex);
    o.normal = UnityObjectToWorldNormal(v.normal);

                
    return o;
}
            
float _Gloss;
float4 _SurfaceColor;
            

float4 frag (Interpolators i) : SV_Target
{
    float3 normal = i.normal;
    float3 wPos = i.wPos;

    float attenuation = LIGHT_ATTENUATION(i);
    float3 light = ApplyLighting(_SurfaceColor, normal, wPos, _Gloss, _LightColor0, attenuation);
                
    return float4(light,1);
}
