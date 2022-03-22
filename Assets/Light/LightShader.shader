Shader "Unlit/LightShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Gloss ("Gloss", Range(0,1)) = 1
        _SurfaceColor("Surface Color", Color) = (1,1,1,1)
        
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry" }
        
        Pass{
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #include "FGLighting.cginc"
            
            ENDCG
        }
        Pass {
            Tags { "LightMode" = "ForwardAdd" }
            Blend One One
            
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd
            #include "FGLighting.cginc"
            
            ENDCG
            
        }
    }
}
