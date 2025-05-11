//
//  scan_fragment.metal
//  engine
//
//  Created by menji on 2025/5/5.
//

#include <metal_stdlib>
using namespace metal;
struct Varying { float4 position [[position]]; float2 uv; };

// 只用一个 uint 顶点 id，就能生成一个三角形覆盖全屏
vertex Varying scanVertex(uint vid [[vertex_id]]) {
    // 定义三个顶点的裁剪空间和 UV
    float2 pos[3] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0)
    };
    float2 uv[3] = {
        float2(0.0, 0.0),
        float2(2.0, 0.0),
        float2(0.0, 2.0)
    };
    Varying out;
    out.position = float4(pos[vid], 0.0, 1.0);
    out.uv       = uv[vid] * 0.5; // 把 (2,0),(0,2) 拉回 (1,0),(0,1)
    return out;
}

struct ScanUniforms {
    float uProgress;   // 当前扫描位置，0→1 循环
    float bandWidth;   // 扫描带宽度（控制扫描线厚度）
    float intensity;   // 高亮强度
    float3 highlightColor; // 扫描线颜色
};

fragment float4 fragmentScan(
    Varying                in         [[stage_in]],
    texture2d<float>       sceneTex   [[ texture(0) ]],
    texture2d<float>       depthTex   [[ texture(1) ]],
    constant ScanUniforms& uni        [[ buffer(4) ]])
{
    // 1. 读取原始场景颜色
    constexpr sampler samp(coord::normalized, address::clamp_to_edge);
    float4 sceneColor = sceneTex.sample(samp, in.uv);

    // 2. 读取深度值
    float depth = depthTex.sample(samp, in.uv).r;

    // 3. 计算与扫描位置的差值
    //    fract 保证 uProgress 在 0→1 循环
    float scanPos = fract(uni.uProgress);
    float diff    = abs(depth - scanPos);

    // 4. 生成平滑的带状权重
    float band = 1.0 - smoothstep(0.0, uni.bandWidth, diff);

    // 5. 混合高亮色
    float3 outRgb = mix(sceneColor.rgb,
                        uni.highlightColor,
                        band * uni.intensity);

//    return float4(outRgb, sceneColor.a);
//    return float4(1,1,0, 1);
    return float4( sceneColor.rgb, 1);
}
