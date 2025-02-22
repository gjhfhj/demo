//
//  Texture.hpp
//  engine
//
//  Created by menji on 2025/2/22.
//

#pragma once
#include <Metal/Metal.hpp>
#include <stb/stb_image.h>
class Texture {
public:
    Texture(const char* filepath, MTL::Device* metalDevice);
    ~Texture();
    MTL::Texture* texture;
    int width, height, channels;

private:
    MTL::Device* device;
};
