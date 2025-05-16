//
//  scan_fragment.metal
//  engine
//
//  Created by menji on 2025/5/5.
//

#include <metal_stdlib>
using namespace metal;

struct VSIn  { float2 pos  [[attribute(0)]]; float2 uv [[attribute(1)]]; };
struct VSOut { float4 position [[position]]; float2 uv; };
struct ScanUniforms {
    float time;       // 动画时间
    float scanSpeed;  // 扫描速度
    float scanWidth;  // 扫描条宽度
    
    float farPlane;
};

float linearizeDepth(float z, float near, float far) {
    float z_ndc = z * 2.0 - 1.0; // [0, 1] → [-1, 1]
    return (2.0 * near * far) / (far + near - z_ndc * (far - near));
}

vertex VSOut passthroughVS(VSIn in [[stage_in]]) {
    VSOut out;
//    out.position = in.pos;
    out.position = float4(in.pos, 0, 1);
    out.uv = in.uv;
    return out;
}

fragment float4 scanEffectPS(VSOut in [[stage_in]],
                             texture2d<float> colorTex [[texture(0)]],
                             texture2d<float> depthTex [[texture(1)]],
                             constant ScanUniforms& uniforms [[buffer(0)]],
                             sampler s [[sampler(0)]]) {
    float2 flippedUV = float2(in.uv.x, 1.0 - in.uv.y); // 翻转 Y 轴
    // 采样颜色和深度
    float4 color = colorTex.sample(s, in.uv);
    float depth = depthTex.sample(s, in.uv).r;

    // 线性化深度（假设 near = 0.1, far = 100.0）
    float linearDepth = linearizeDepth(depth, 0.1, 100.0);

    // 计算扫描位置
    float scanPos = fmod(uniforms.time * uniforms.scanSpeed, uniforms.farPlane);
    float scanDist = abs(linearDepth - scanPos); // 距离扫描前沿的距离

    // 扫描效果：当距离小于宽度时，叠加扫描颜色
    float scanEffect = smoothstep(uniforms.scanWidth, 0.0, scanDist);
    float4 scanColor = float4(1.0, 0.0, 0.0, 1.0); // 扫描条颜色

    // 混合原始颜色和扫描颜色
     return mix(color, scanColor, scanEffect * 0.5);
    // return float4(depth,depth,depth,1);
//    return color;
 }
