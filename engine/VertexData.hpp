//
//  vertextData.hpp
//  engine
//
//  Created by menji on 2025/2/22.
//

#pragma once
#include <simd/simd.h>

using namespace simd;

struct Vertex {
    float3 position;
    float3 normal;
    float3 tangent;
    float3 bitangent;
    float2 textureCoordinate;
    int diffuseTextureIndex;
    int specularTextureIndex;
    int normalMapIndex;
    int emissiveMapIndex;
};

struct TextureInfo {
    int width;
    int height;
};

struct VertexData {
    float4 position [[position]];
    float4 normal;
};


struct TransformationData {
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 perspectiveMatrix;
};
