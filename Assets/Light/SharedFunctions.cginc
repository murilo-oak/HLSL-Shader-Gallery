#define TAU 6.28318530718

float InverseLerp(float a, float b, float v) {
    return (v-a)/(b-a);
}

float3 LamportLight(float3 normal, float3 lightDir) {
    float3 DifuseLightMask = saturate(dot(normal, lightDir));
    return DifuseLightMask;
}

float3 PhongLight(float3 normal, float3 lightDir,float3 viewDir, float glossinessExp) {
    float3 refletedlightDir = reflect(lightDir, normal);
    float3 specularLightMask = saturate(dot(viewDir,refletedlightDir));

    specularLightMask = pow(specularLightMask, glossinessExp);

    return specularLightMask;
}

float3 BlinnPhongLight(float3 normal, float3 lightDir,float3 viewDir, float gloss) {
    normal = normalize(normal);
    float3 halfVector = normalize(viewDir + lightDir);
    float3 specularBlinnLightMask = saturate(dot(normal,halfVector));
    
    specularBlinnLightMask  = pow(specularBlinnLightMask, gloss);

    return specularBlinnLightMask;
}

float3 ApplyLighting(float4 surfColor, float3 normal, float3 wPos, float glossinesss, float3 light_color, float attenuation) {
    float3 lightDir = normalize(UnityWorldSpaceLightDir(wPos));
    float3 viewDir = normalize(_WorldSpaceCameraPos - wPos);
    
    //Remap glossiness slider to exponent
    float3 difuseLightMask = LamportLight(normal, lightDir) * attenuation;
    float specularExponent = exp2(glossinesss * 11) + 2;
    

    float3 specularBlinnLightMask = BlinnPhongLight(normal, lightDir, viewDir, specularExponent) * attenuation;

    //clamp specular light behind object in edge cases
    specularBlinnLightMask *= (difuseLightMask > 0);
    
    return (difuseLightMask * surfColor  + specularBlinnLightMask ) * light_color;
}

float3 fresnel(float3 view_direction, float3 normal) {
    return 1 - dot(view_direction, normal);
} 
            
            
            