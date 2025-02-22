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
    float2 textureCoordinate;
};
