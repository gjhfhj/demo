//
//  vertextData.hpp
//  engine
//
//  Created by menji on 2025/2/22.
//

#pragma once
#include <simd/simd.h>

using namespace simd;

struct VertexData {
    float4 position;
    float4 normal;
};


struct TransformationData {
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 perspectiveMatrix;
};
