//
//  mtl_engine.hpp
//  engine
//
//  Created by menji on 2025/2/20.
//


#pragma once

#define GLFW_INCLUDE_NONE
#import <GLFW/glfw3.h>
#define GLFW_EXPOSE_NATIVE_COCOA
#import <GLFW/glfw3native.h>

#include <Metal/Metal.hpp>
#include <Metal/Metal.h>
#include <QuartzCore/CAMetalLayer.hpp>
#include <QuartzCore/CAMetalLayer.h>
#include <QuartzCore/QuartzCore.hpp>

#include <simd/simd.h>

#include "VertexData.hpp"
#include "Texture.hpp"
#include <stb/stb_image.h>

#include <filesystem>

#include "AAPLMathUtilities.h"


class MTLEngine {
public:
    void init();
    void run();
    void cleanup();

private:
    void initDevice();
    void initWindow();

    void createCube();
    void createBuffers();
    void createDefaultLibrary();
    void createCommandQueue();
    void createRenderPipeline();
    void createLightSourceRenderPipeline();
    void createDepthAndMSAATextures();
    void createRenderPassDescriptor();

    void draw();
    void encodeRenderCommand(MTL::RenderCommandEncoder* renderEncoder);
    void sendRenderCommand();

    static void frameBufferSizeCallback(GLFWwindow *window, int width, int height); //调整窗口大小时，
    void resizeFrameBuffer(int width, int height);                                  //解决metalLayer.drawableSize 的分辨率不会更新的问题
    // Upon resizing, update Depth and MSAA Textures.
    void updateRenderPassDescriptor();
    
    MTL::Device* metalDevice;
    GLFWwindow* glfwWindow;
    NSWindow* metalWindow;
    CAMetalLayer* metalLayer;
    CA::MetalDrawable* metalDrawable;

    MTL::Library* metalDefaultLibrary;
    MTL::CommandQueue* metalCommandQueue;
    MTL::CommandBuffer* metalCommandBuffer;
    MTL::RenderPipelineState* metalRenderPSO;
    MTL::RenderPipelineState* metalLightSourceRenderPSO;
    
    MTL::Buffer* cubeVertexBuffer;
    MTL::Buffer* cubeTransformationBuffer;
    MTL::Buffer* lightVertexBuffer;
    MTL::Buffer* lightTransformationBuffer;

    
    MTL::DepthStencilState* depthStencilState;
    MTL::RenderPassDescriptor* renderPassDescriptor;
    MTL::Texture* msaaRenderTargetTexture = nullptr;
    MTL::Texture* depthTexture;
    int sampleCount = 4;


    Texture* grassTexture;
};
