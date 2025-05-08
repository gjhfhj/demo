//
//  scan_compute.metal
//  engine
//
//  Created by menji on 2025/5/5.
//

//#include <metal_stdlib>
//using namespace metal;
//kernel void computeScan(texture2d<float, access::sample> depthTex [[texture(0)]],
//                        texture2d<uchar, access::read> inColor [[texture(1)]],
//                        texture2d<uchar, access::write> outColor [[texture(2)]],
//                        constant float& scanTime [[buffer(0)]],
//                        uint2 gid [[thread_position_in_grid]]) {
//    if (gid.x >= outColor.get_width() || gid.y >= outColor.get_height()) return;
//    float depth = depthTex.sample(sampler(coord::pixel), float2(gid) / float2(outColor.get_width(), outColor.get_height())).r;
//    float scanPos = fract(scanTime);
//    // 读取原始颜色 (BGRA)
//    uchar4 orig = inColor.read(gid);
//    float4 color = float4(orig) / 255.0;
//    float highlight = (depth < scanPos) ? 0.5 : 0.0; // 半透明叠加
//    float4 outC = clamp(color + float4(highlight, highlight, highlight, 0.0), 0.0, 1.0);
//    outColor.write(uchar4(outC * 255.0), gid);
//}
