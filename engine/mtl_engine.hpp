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


class MTLEngine {
public:
    void init();
    void run();
    void cleanup();

private:
    void initDevice();
    void initWindow();

    void createSquare();
    void createDefaultLibrary();
    void createCommandQueue();
    void createRenderPipeline();

    void draw();
    void encodeRenderCommand(MTL::RenderCommandEncoder* renderEncoder);
    void sendRenderCommand();

    static void frameBufferSizeCallback(GLFWwindow *window, int width, int height); //调整窗口大小时，
    void resizeFrameBuffer(int width, int height);                                  //解决metalLayer.drawableSize 的分辨率不会更新的问题
    
    MTL::Device* metalDevice;
    GLFWwindow* glfwWindow;
    NSWindow* metalWindow;
    CAMetalLayer* metalLayer;
    CA::MetalDrawable* metalDrawable;

    MTL::Library* metalDefaultLibrary;
    MTL::CommandQueue* metalCommandQueue;
    MTL::CommandBuffer* metalCommandBuffer;
    MTL::RenderPipelineState* metalRenderPSO;
    
    MTL::Buffer* squareVertexBuffer;

    Texture* grassTexture;
};
