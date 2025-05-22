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

#include "timer.hpp"
#include "VertexData.hpp"
#include "Texture.hpp"
#include <stb/stb_image.h>

#include "TextureArray.hpp"
#include "mesh.hpp"
#include "model.hpp"

#include <filesystem>

#include "AAPLMathUtilities.h"



class MTLEngine {
public:
    void init();
    void run();
    void cleanup();

private:
    Timer timer;
    void initDevice();
    void initWindow();
    
    void loadMeshes();
    void createCube();
    void createBuffers();
    void createDefaultLibrary();
    void createCommandQueue();
    void createModelRenderPipeline();
    void createRenderPipeline();
    void createLightSourceRenderPipeline();
    
    void createScanFragmentPipeline();
    void createScanComputePipeline();

    void createDepthAndMSAATextures();
    void createOffscreenTextures();
    void createRenderPassDescriptor();
    void createOffscreenPassDescriptor();
    void postProcessPass();
    
    void draw();
    void encodeRenderCommand(MTL::RenderCommandEncoder* renderEncoder);
    void copyDepthTextureAfterRenderEncodedBeforeSendingCommand();
    void sendRenderCommand();
    
    // Upon resizing, update Depth and MSAA Textures.
    void updateRenderPassDescriptor();
    void updateOffscreenPassDescriptor();
    
    void writeDepthTexture();

    static void frameBufferSizeCallback(GLFWwindow *window, int width, int height); //调整窗口大小时，
    void resizeFrameBuffer(int width, int height);                                  //解决metalLayer.drawableSize 的分辨率不会更新的问题
    static void keyCallback(GLFWwindow* window, int key, int scancode, int action, int mods);
    
    MTL::Device* metalDevice;
    GLFWwindow* glfwWindow;
    NSWindow* metalWindow;
    CAMetalLayer* metalLayer;
    CA::MetalDrawable* metalDrawable;

    MTL::Library* metalDefaultLibrary;
    MTL::CommandQueue* metalCommandQueue;
    MTL::CommandBuffer* metalCommandBuffer;
    MTL::RenderPipelineState* modelRenderPSO;
    MTL::RenderPipelineState* metalRenderPSO;
    MTL::RenderPipelineState* metalLightSourceRenderPSO;
    
    MTL::RenderPipelineState* metalScanPSO;
    MTL::ComputePipelineState* metalScanCPSO;
    
    MTL::Buffer* cubeVertexBuffer;
    MTL::Buffer* cubeTransformationBuffer;
    MTL::Buffer* lightVertexBuffer;
    MTL::Buffer* lightTransformationBuffer;

    
    MTL::DepthStencilState* depthStencilState;
    MTL::SamplerState* samplerState;
    MTL::RenderPassDescriptor* renderPassDescriptor;
    MTL::RenderPassDescriptor* offscreenPassDesc = nullptr;
    MTL::Texture* msaaRenderTargetTexture = nullptr;
    MTL::Texture* depthTexture;
    MTL::Texture* resolvedDepthTexture;
    MTL::Texture* sceneMSAATexture;
    MTL::Texture* sceneTargetColorTexture; //offscreen目标颜色纹理
    int sampleCount = 4;

    Model* model;
    Mesh* mesh;
    Texture* grassTexture;
    
};
