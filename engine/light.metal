//
//  light.metal
//  engine
//
//  Created by menji on 2025/3/3.
//

#include <metal_stdlib>

using namespace metal;

#include "VertexData.hpp"


vertex VertexData lightVertexShader(uint vertexID [[vertex_id]],
             constant VertexData* vertexData,
             constant TransformationData* transformationData)
{
    VertexData out;
    
    out.position = transformationData->perspectiveMatrix * transformationData->viewMatrix * transformationData->modelMatrix * vertexData[vertexID].position;
    return out;
}

fragment float4 lightFragmentShader(VertexData in [[stage_in]],
                                    constant float4& lightColor [[ buffer(0) ]]) {
    return lightColor;
}
