//
//  mtl_engine.mm
//  engine
//
//  Created by menji on 2025/2/20.
//

#define STB_IMAGE_WRITE_IMPLEMENTATION
#include "stb_image_write.h"

#include "mtl_engine.hpp"

#include <iostream>
// 只导入 std::cerr
using std::cerr;

void MTLEngine::init(){
    printf("-------------------------------Engine to init--------------------------------\n");
    initDevice();
    initWindow();
    
    createCube();
    createBuffers();
    createDefaultLibrary();
    createCommandQueue();
    createRenderPipeline();
    createLightSourceRenderPipeline();
    createDepthAndMSAATextures();
    createRenderPassDescriptor();
    printf("-------------------------Engine inited(the next: run)-------------------------\n");
}

void MTLEngine::run(){
    printf("-----------------Engine to run(the next: to end and cleanup)------------------\n");
    
    while(!glfwWindowShouldClose(glfwWindow)){
        @autoreleasepool {
            metalDrawable = (__bridge CA::MetalDrawable*)[metalLayer nextDrawable];
            draw();
        }
        glfwPollEvents();
    }
    
    printf("------------------- Engine ends(the next: cleanup memory)----------------------\n");
}


void MTLEngine::cleanup(){
    printf("-------------------------------Cleanup the memory------------------------------\n");
    
    glfwTerminate();
    cubeTransformationBuffer->release();
    lightTransformationBuffer->release();
    msaaRenderTargetTexture->release();
    depthTexture->release();
    renderPassDescriptor->release();
    metalDevice->release();    
    printf("--------------------------------------Done-------------------------------------\n");
}

void MTLEngine::initDevice(){
    metalDevice = MTL::CreateSystemDefaultDevice();
    
    printf("metalDevice inited.\n");
}

void MTLEngine::initWindow() {
    glfwInit();
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    glfwWindow = glfwCreateWindow(800, 800, "Metal Engine", NULL, NULL);
    
    if (!glfwWindow ) {
        glfwTerminate();
        exit(EXIT_FAILURE);
    }
    
    glfwSetWindowUserPointer(glfwWindow, this);
    glfwSetFramebufferSizeCallback(glfwWindow, frameBufferSizeCallback);
    int width, height;
    glfwGetFramebufferSize(glfwWindow, &width, &height);
    
    metalWindow = glfwGetCocoaWindow(glfwWindow);
    metalLayer = [CAMetalLayer layer];
    metalLayer.device = (__bridge id<MTLDevice>)metalDevice;
    metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    metalLayer.drawableSize = CGSizeMake(width, height);
    metalWindow.contentView.layer = metalLayer;
    metalWindow.contentView.wantsLayer = YES;
    
    metalDrawable = (__bridge CA::MetalDrawable*)[metalLayer nextDrawable];//首次创建，为了第一帧加上MSAA/Drawable Textures 
    printf("glfw window inited.\n");
}



void MTLEngine::createCube() {
    // Cube for use in a right-handed coordinate system with triangle faces
    // specified with a Counter-Clockwise winding order.
    VertexData cubeVertices[] = {
        // Front face            // Normals
        {{-0.5,-0.5, 0.5, 1.0}, {0.0, 0.0, 1.0, 1.0}},
        {{ 0.5,-0.5, 0.5, 1.0}, {0.0, 0.0, 1.0, 1.0}},
        {{ 0.5, 0.5, 0.5, 1.0}, {0.0, 0.0, 1.0, 1.0}},
        {{ 0.5, 0.5, 0.5, 1.0}, {0.0, 0.0, 1.0, 1.0}},
        {{-0.5, 0.5, 0.5, 1.0}, {0.0, 0.0, 1.0, 1.0}},
        {{-0.5,-0.5, 0.5, 1.0}, {0.0, 0.0, 1.0, 1.0}},
        
        // Back face
        {{ 0.5,-0.5,-0.5, 1.0}, {0.0, 0.0,-1.0, 1.0}},
        {{-0.5,-0.5,-0.5, 1.0}, {0.0, 0.0,-1.0, 1.0}},
        {{-0.5, 0.5,-0.5, 1.0}, {0.0, 0.0,-1.0, 1.0}},
        {{-0.5, 0.5,-0.5, 1.0}, {0.0, 0.0,-1.0, 1.0}},
        {{ 0.5, 0.5,-0.5, 1.0}, {0.0, 0.0,-1.0, 1.0}},
        {{ 0.5,-0.5,-0.5, 1.0}, {0.0, 0.0,-1.0, 1.0}},

        // Top face
        {{-0.5, 0.5, 0.5, 1.0}, {0.0, 1.0, 0.0, 1.0}},
        {{ 0.5, 0.5, 0.5, 1.0}, {0.0, 1.0, 0.0, 1.0}},
        {{ 0.5, 0.5,-0.5, 1.0}, {0.0, 1.0, 0.0, 1.0}},
        {{ 0.5, 0.5,-0.5, 1.0}, {0.0, 1.0, 0.0, 1.0}},
        {{-0.5, 0.5,-0.5, 1.0}, {0.0, 1.0, 0.0, 1.0}},
        {{-0.5, 0.5, 0.5, 1.0}, {0.0, 1.0, 0.0, 1.0}},

        // Bottom face
        {{-0.5,-0.5,-0.5, 1.0}, {0.0,-1.0, 0.0, 1.0}},
        {{ 0.5,-0.5,-0.5, 1.0}, {0.0,-1.0, 0.0, 1.0}},
        {{ 0.5,-0.5, 0.5, 1.0}, {0.0,-1.0, 0.0, 1.0}},
        {{ 0.5,-0.5, 0.5, 1.0}, {0.0,-1.0, 0.0, 1.0}},
        {{-0.5,-0.5, 0.5, 1.0}, {0.0,-1.0, 0.0, 1.0}},
        {{-0.5,-0.5,-0.5, 1.0}, {0.0,-1.0, 0.0, 1.0}},

        // Left face
        {{-0.5,-0.5,-0.5, 1.0}, {-1.0,0.0, 0.0, 1.0}},
        {{-0.5,-0.5, 0.5, 1.0}, {-1.0,0.0, 0.0, 1.0}},
        {{-0.5, 0.5, 0.5, 1.0}, {-1.0,0.0, 0.0, 1.0}},
        {{-0.5, 0.5, 0.5, 1.0}, {-1.0,0.0, 0.0, 1.0}},
        {{-0.5, 0.5,-0.5, 1.0}, {-1.0,0.0, 0.0, 1.0}},
        {{-0.5,-0.5,-0.5, 1.0}, {-1.0,0.0, 0.0, 1.0}},

        // Right face
        {{ 0.5,-0.5, 0.5, 1.0}, {1.0, 0.0, 0.0, 1.0}},
        {{ 0.5,-0.5,-0.5, 1.0}, {1.0, 0.0, 0.0, 1.0}},
        {{ 0.5, 0.5,-0.5, 1.0}, {1.0, 0.0, 0.0, 1.0}},
        {{ 0.5, 0.5,-0.5, 1.0}, {1.0, 0.0, 0.0, 1.0}},
        {{ 0.5, 0.5, 0.5, 1.0}, {1.0, 0.0, 0.0, 1.0}},
        {{ 0.5,-0.5, 0.5, 1.0}, {1.0, 0.0, 0.0, 1.0}},
    };
    
    cubeVertexBuffer = metalDevice->newBuffer(&cubeVertices, sizeof(cubeVertices), MTL::ResourceStorageModeShared);
    
    VertexData lightSource[] = {
        // Front face            // Normals
        {{-0.5,-0.5, 0.5, 1.0}, {0.0, 0.0, 1.0, 1.0}},
        {{ 0.5,-0.5, 0.5, 1.0}, {0.0, 0.0, 1.0, 1.0}},
        {{ 0.5, 0.5, 0.5, 1.0}, {0.0, 0.0, 1.0, 1.0}},
        {{ 0.5, 0.5, 0.5, 1.0}, {0.0, 0.0, 1.0, 1.0}},
        {{-0.5, 0.5, 0.5, 1.0}, {0.0, 0.0, 1.0, 1.0}},
        {{-0.5,-0.5, 0.5, 1.0}, {0.0, 0.0, 1.0, 1.0}},
        
        // Back face
        {{ 0.5,-0.5,-0.5, 1.0}, {0.0, 0.0,-1.0, 1.0}},
        {{-0.5,-0.5,-0.5, 1.0}, {0.0, 0.0,-1.0, 1.0}},
        {{-0.5, 0.5,-0.5, 1.0}, {0.0, 0.0,-1.0, 1.0}},
        {{-0.5, 0.5,-0.5, 1.0}, {0.0, 0.0,-1.0, 1.0}},
        {{ 0.5, 0.5,-0.5, 1.0}, {0.0, 0.0,-1.0, 1.0}},
        {{ 0.5,-0.5,-0.5, 1.0}, {0.0, 0.0,-1.0, 1.0}},

        // Top face
        {{-0.5, 0.5, 0.5, 1.0}, {0.0, 1.0, 0.0, 1.0}},
        {{ 0.5, 0.5, 0.5, 1.0}, {0.0, 1.0, 0.0, 1.0}},
        {{ 0.5, 0.5,-0.5, 1.0}, {0.0, 1.0, 0.0, 1.0}},
        {{ 0.5, 0.5,-0.5, 1.0}, {0.0, 1.0, 0.0, 1.0}},
        {{-0.5, 0.5,-0.5, 1.0}, {0.0, 1.0, 0.0, 1.0}},
        {{-0.5, 0.5, 0.5, 1.0}, {0.0, 1.0, 0.0, 1.0}},

        // Bottom face
        {{-0.5,-0.5,-0.5, 1.0}, {0.0,-1.0, 0.0, 1.0}},
        {{ 0.5,-0.5,-0.5, 1.0}, {0.0,-1.0, 0.0, 1.0}},
        {{ 0.5,-0.5, 0.5, 1.0}, {0.0,-1.0, 0.0, 1.0}},
        {{ 0.5,-0.5, 0.5, 1.0}, {0.0,-1.0, 0.0, 1.0}},
        {{-0.5,-0.5, 0.5, 1.0}, {0.0,-1.0, 0.0, 1.0}},
        {{-0.5,-0.5,-0.5, 1.0}, {0.0,-1.0, 0.0, 1.0}},

        // Left face
        {{-0.5,-0.5,-0.5, 1.0}, {-1.0,0.0, 0.0, 1.0}},
        {{-0.5,-0.5, 0.5, 1.0}, {-1.0,0.0, 0.0, 1.0}},
        {{-0.5, 0.5, 0.5, 1.0}, {-1.0,0.0, 0.0, 1.0}},
        {{-0.5, 0.5, 0.5, 1.0}, {-1.0,0.0, 0.0, 1.0}},
        {{-0.5, 0.5,-0.5, 1.0}, {-1.0,0.0, 0.0, 1.0}},
        {{-0.5,-0.5,-0.5, 1.0}, {-1.0,0.0, 0.0, 1.0}},

        // Right face
        {{ 0.5,-0.5, 0.5, 1.0}, {1.0, 0.0, 0.0, 1.0}},
        {{ 0.5,-0.5,-0.5, 1.0}, {1.0, 0.0, 0.0, 1.0}},
        {{ 0.5, 0.5,-0.5, 1.0}, {1.0, 0.0, 0.0, 1.0}},
        {{ 0.5, 0.5,-0.5, 1.0}, {1.0, 0.0, 0.0, 1.0}},
        {{ 0.5, 0.5, 0.5, 1.0}, {1.0, 0.0, 0.0, 1.0}},
        {{ 0.5,-0.5, 0.5, 1.0}, {1.0, 0.0, 0.0, 1.0}},
    };
    
    lightVertexBuffer = metalDevice->newBuffer(&lightSource, sizeof(lightSource), MTL::ResourceStorageModeShared);
}

void MTLEngine::createBuffers(){
    cubeTransformationBuffer = metalDevice->newBuffer(sizeof(TransformationData), MTL::ResourceStorageModeShared);
    lightTransformationBuffer = metalDevice->newBuffer(sizeof(TransformationData), MTL::ResourceStorageModeShared);
}

void MTLEngine::createDefaultLibrary(){
    metalDefaultLibrary = metalDevice->newDefaultLibrary();
    if(!metalDefaultLibrary){
        std::cerr << "Failed to load default library.\n";
        std::exit(-1);
    }
    
    printf("Default library loaded.\n");
}


void MTLEngine::createCommandQueue(){
    metalCommandQueue = metalDevice->newCommandQueue();
    
    printf("metalCommandQueue created.\n");
}


void MTLEngine::createRenderPipeline(){
    MTL::Function* vertexShader = metalDefaultLibrary->newFunction(NS::String::string("vertexShader", NS::ASCIIStringEncoding));
    assert(vertexShader); //assert() 检查 参数 是否为空，如果为空，表示创建管线描述符失败，会中断程序。
    MTL::Function* fragmentShader = metalDefaultLibrary->newFunction(NS::String::string("fragmentShader", NS::ASCIIStringEncoding));
    assert(fragmentShader);
    
    MTL::RenderPipelineDescriptor* renderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();
//    renderPipelineDescriptor->setLabel(NS::String::string("Square Rendering Pipeline", NS::ASCIIStringEncoding));
    renderPipelineDescriptor->setVertexFunction(vertexShader);
    renderPipelineDescriptor->setFragmentFunction(fragmentShader);
    assert(renderPipelineDescriptor);
    MTL::PixelFormat pixelFormat = (MTL::PixelFormat)metalLayer.pixelFormat;
    renderPipelineDescriptor->colorAttachments()->object(0)->setPixelFormat(pixelFormat);
    renderPipelineDescriptor->setSampleCount(4);
    renderPipelineDescriptor->setLabel(NS::String::string("Cube Render Pipeline", NS::ASCIIStringEncoding));
    renderPipelineDescriptor->setDepthAttachmentPixelFormat(MTL::PixelFormatDepth32Float);
    renderPipelineDescriptor->setTessellationOutputWindingOrder(MTL::WindingClockwise);

    NS::Error* error;
    metalRenderPSO = metalDevice->newRenderPipelineState(renderPipelineDescriptor, &error);
    
    if (metalRenderPSO == nil) {
        std::cout<<"Error creating render pipeline state: "<< error << std::endl;
        std::exit(0);
    }
    
    MTL::DepthStencilDescriptor* depthStencilDescriptor = MTL::DepthStencilDescriptor::alloc()->init();
    depthStencilDescriptor->setDepthCompareFunction(MTL::CompareFunctionLessEqual);
    depthStencilDescriptor->setDepthWriteEnabled(true); //to allow the gpu to write to the depth buffe
    depthStencilState = metalDevice->newDepthStencilState(depthStencilDescriptor);
    
//    depthStencilDescriptor->release();    //这个要吗？？？别的都配置了就release了
    renderPipelineDescriptor->release();
    vertexShader->release();
    fragmentShader->release();
    
}

void MTLEngine::createLightSourceRenderPipeline() {
    MTL::Function* vertexShader = metalDefaultLibrary->newFunction(NS::String::string("lightVertexShader", NS::ASCIIStringEncoding));
    assert(vertexShader);
    MTL::Function* fragmentShader = metalDefaultLibrary->newFunction(NS::String::string("lightFragmentShader", NS::ASCIIStringEncoding));
    assert(fragmentShader);
    
    MTL::RenderPipelineDescriptor* renderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();
    renderPipelineDescriptor->setVertexFunction(vertexShader);
    renderPipelineDescriptor->setFragmentFunction(fragmentShader);
    assert(renderPipelineDescriptor);
    MTL::PixelFormat pixelFormat = (MTL::PixelFormat)metalLayer.pixelFormat;
    renderPipelineDescriptor->colorAttachments()->object(0)->setPixelFormat(pixelFormat);
    renderPipelineDescriptor->setSampleCount(4);
    renderPipelineDescriptor->setLabel(NS::String::string("Light Source Render Pipeline", NS::ASCIIStringEncoding));
    renderPipelineDescriptor->setDepthAttachmentPixelFormat(MTL::PixelFormatDepth32Float);
    renderPipelineDescriptor->setTessellationOutputWindingOrder(MTL::WindingClockwise);
    
    NS::Error* error;
    metalLightSourceRenderPSO = metalDevice->newRenderPipelineState(renderPipelineDescriptor, &error);
    
    renderPipelineDescriptor->release();
}

void MTLEngine::createDepthAndMSAATextures() {
    MTL::TextureDescriptor* msaaTextureDescriptor = MTL::TextureDescriptor::alloc()->init();
    msaaTextureDescriptor->setTextureType(MTL::TextureType2DMultisample);
    msaaTextureDescriptor->setPixelFormat(MTL::PixelFormatBGRA8Unorm);
    msaaTextureDescriptor->setWidth(metalLayer.drawableSize.width);
    msaaTextureDescriptor->setHeight(metalLayer.drawableSize.height);
    msaaTextureDescriptor->setSampleCount(sampleCount);
    msaaTextureDescriptor->setUsage(MTL::TextureUsageRenderTarget);
    
    msaaRenderTargetTexture = metalDevice->newTexture(msaaTextureDescriptor);
    
    MTL::TextureDescriptor* depthTextureDescriptor = MTL::TextureDescriptor::alloc()->init();
    depthTextureDescriptor->setTextureType(MTL::TextureType2DMultisample);
    depthTextureDescriptor->setPixelFormat(MTL::PixelFormatDepth32Float);
    depthTextureDescriptor->setWidth(metalLayer.drawableSize.width);
    depthTextureDescriptor->setHeight(metalLayer.drawableSize.height);
    depthTextureDescriptor->setUsage(MTL::TextureUsageRenderTarget);
    depthTextureDescriptor->setSampleCount(sampleCount);
    
    depthTexture = metalDevice->newTexture(depthTextureDescriptor);
    
    msaaTextureDescriptor->release();
    depthTextureDescriptor->release();
    
    MTL::TextureDescriptor* resolvedDepthTextureDescriptor = MTL::TextureDescriptor::alloc()->init();
    resolvedDepthTextureDescriptor->setTextureType(MTL::TextureType2D);           // 2D 纹理
    resolvedDepthTextureDescriptor->setPixelFormat(MTL::PixelFormatDepth32Float);     // 浮点格式存储深度值
    resolvedDepthTextureDescriptor->setWidth(metalLayer.drawableSize.width);      // 宽度
    resolvedDepthTextureDescriptor->setHeight(metalLayer.drawableSize.height);    // 高度
    resolvedDepthTextureDescriptor->setUsage(MTL::TextureUsageRenderTarget | MTL::TextureUsageShaderRead); // 可渲染和读取
    resolvedDepthTextureDescriptor->setStorageMode(MTL::StorageModeShared); //如果你创建 resolveDepthTexture 时用了 storageModePrivate，就会报错或根本读不出来。shaderd才能用getBytes直接读回到CPU。
    resolvedDepthTexture = metalDevice->newTexture(resolvedDepthTextureDescriptor);
    resolvedDepthTextureDescriptor->release();
}

void MTLEngine::createRenderPassDescriptor() {
    renderPassDescriptor = MTL::RenderPassDescriptor::alloc()->init();

    MTL::RenderPassColorAttachmentDescriptor* colorAttachment = renderPassDescriptor->colorAttachments()->object(0);
    MTL::RenderPassDepthAttachmentDescriptor* depthAttachment = renderPassDescriptor->depthAttachment();

    colorAttachment->setTexture(msaaRenderTargetTexture);
    colorAttachment->setResolveTexture(metalDrawable->texture());
    colorAttachment->setLoadAction(MTL::LoadActionClear);
    colorAttachment->setClearColor(MTL::ClearColor(41.0f/255.0f, 42.0f/255.0f, 48.0f/255.0f, 1.0));
    colorAttachment->setStoreAction(MTL::StoreActionMultisampleResolve);

    depthAttachment->setTexture(depthTexture);
    depthAttachment->setLoadAction(MTL::LoadActionClear);
    depthAttachment->setStoreAction(MTL::StoreActionStore);
    depthAttachment->setClearDepth(1.0);
    
    depthAttachment->setResolveTexture(resolvedDepthTexture);
    depthAttachment->setStoreAction(MTL::StoreActionMultisampleResolve);  // 解析多重采样数据
}

void MTLEngine::updateRenderPassDescriptor() {
    renderPassDescriptor->colorAttachments()->object(0)->setTexture(msaaRenderTargetTexture);
    renderPassDescriptor->colorAttachments()->object(0)->setResolveTexture(metalDrawable->texture());
    renderPassDescriptor->depthAttachment()->setTexture(depthTexture);
}


void MTLEngine::draw(){

    printf("Draw:\t");
    sendRenderCommand();
    
}

void MTLEngine::sendRenderCommand() {
    printf("Sending render command.\t");
    
    metalCommandBuffer = metalCommandQueue->commandBuffer();

    updateRenderPassDescriptor();
    MTL::RenderCommandEncoder* renderCommandEncoder = metalCommandBuffer->renderCommandEncoder(renderPassDescriptor);
    encodeRenderCommand(renderCommandEncoder);
    renderCommandEncoder->endEncoding();

//    copyDepthTextureAfterRenderEncodedBeforeSendingCommand();   //在渲染后复制深度纹理为了获取到深度图
    
    
    
    metalCommandBuffer->presentDrawable(metalDrawable);
    metalCommandBuffer->commit();
    metalCommandBuffer->waitUntilCompleted();
    
    // 1. 定义你要读的区域：origin + size
    MTL::Region region = MTL::Region(
        0,                                      // x 起点
        0,                                      // y 起点
        metalLayer.drawableSize.width,         // width
        metalLayer.drawableSize.height         // height
    );

    NS::UInteger bytesPerRow = 4 * metalLayer.drawableSize.width; // 2. 每个像素 4 字节（32位浮点）
    void* depthData = malloc(bytesPerRow * metalLayer.drawableSize.height); // 3. 分配内存
    // 4. 真正从纹理里拷数据到 depthData
    resolvedDepthTexture->getBytes(
        depthData,         // 目标内存指针
        bytesPerRow,       // 每一行写多少字节
        region,            // 读哪块区域
        /* level */ 0      // 哪个 mipmap 级别，通常最详细的就是 level 0
    );

    
    float* depthValues = (float*)depthData;
    int width = metalLayer.drawableSize.width;
    int height = metalLayer.drawableSize.height;
    uint8_t* grayImage = new uint8_t[width * height]; // 灰度图像缓冲区
    
    for (int i = 0; i < width * height; i++) {
        grayImage[i] = static_cast<uint8_t>(depthValues[i] * 255.0f); // 转换为灰度值 [0, 255]
    }
    
//    stbi_write_png("/Users/menji/Movies/depthPNG/depth.png", width, height, 1, grayImage, width);
    int result = stbi_write_png("/Users/menji/Movies/depthPNG/depth.png",
                                width,
                                height,
                                1,
                                grayImage,
                                width);
    if (!result) {
        std::cerr << "Failed to write depth PNG\n";
    }
    
    free(depthData); // 释放内存
    delete[] grayImage;
    
    printf("sended\n");
}

void MTLEngine::copyDepthTextureAfterRenderEncodedBeforeSendingCommand() {
    MTL::BlitCommandEncoder* blitEncoder = metalCommandBuffer->blitCommandEncoder();
    blitEncoder->copyFromTexture(depthTexture, 0, 0, resolvedDepthTexture, 0 , 0,
                                metalLayer.drawableSize.width,
                                metalLayer.drawableSize.height);
    // Grok给我的是resolveTexture，实际上跳转到BlitCommandEncoder类时没有这个，chatGPT告诉我是：
                                                            // 解析多重采样纹理到普通纹理
                                                            //    void copyFromTexture(const Texture* sourceTexture,
                                                            //                         NSUInteger sourceSlice,
                                                            //                         NSUInteger sourceLevel,
                                                            //                         const Texture* destinationTexture,
                                                            //                         NSUInteger destinationSlice,
                                                            //                         NSUInteger destinationLevel,
                                                            //                         NSUInteger sliceCount,
                                                            //                         NSUInteger levelCount);
    blitEncoder->endEncoding();
}

void MTLEngine::encodeRenderCommand(MTL::RenderCommandEncoder* renderCommandEncoder) {
    // Moves the Cube 1 unit down the negative Z-axis
       matrix_float4x4 translationMatrix = matrix4x4_translation(0.0f, -0.9f, 0.0f);

       matrix_float4x4 modelMatrix = translationMatrix;
       
       float time = glfwGetTime();
       float oscillation = sin(time);  // oscillates between -1 and 1
       float zPosition = 1.5 + 1.5 * oscillation;  // maps oscillation to range [0, 3]

       simd::float3 R = simd::float3 {1, 0, 0}; // Unit-Right
       simd::float3 U = simd::float3 {0, 1, 0}; // Unit-Up
       simd::float3 F = simd::float3 {0, 0,-1}; // Unit-Forward
       simd::float3 P = simd::float3 {0, 0, 1}; // Camera Position in World Space
       
       matrix_float4x4 viewMatrix = matrix_make_rows(R.x, R.y, R.z, dot(-R, P),
                                                     U.x, U.y, U.z, dot(-U, P),
                                                    -F.x,-F.y,-F.z, dot( F, P),
                                                     0, 0, 0, 1);
       
       float aspectRatio = (metalLayer.frame.size.width / metalLayer.frame.size.height);
       float fov = 90 * (M_PI / 180.0f);
       float nearZ = 0.1f;
       float farZ = 100.0f;
       
       matrix_float4x4 perspectiveMatrix = matrix_perspective_right_hand(fov, aspectRatio, nearZ, farZ);
       TransformationData transformationData = { modelMatrix, viewMatrix, perspectiveMatrix };
       memcpy(cubeTransformationBuffer->contents(), &transformationData, sizeof(transformationData));
       
       // Cube Fragment Shader Data
       simd_float4 cubeColor = simd_make_float4(0.5, 0.9, 0.7, 1.0);
       simd_float4 lightColor = simd_make_float4(1.0, 1.0, 1.0, 1.0);
       simd_float4 lightPosition = simd_make_float4(0 - 3*cos(glfwGetTime()/1.0), 1.2,-4 + sin(glfwGetTime()/1.0), 1);
       simd_float4 cameraPosition = simd_make_float4(P.xyz, 1.0);

       renderCommandEncoder->setFragmentBytes(&cubeColor, sizeof(cubeColor), 0);
       renderCommandEncoder->setFragmentBytes(&lightColor, sizeof(lightColor), 1);
       renderCommandEncoder->setFragmentBytes(&lightPosition, sizeof(lightPosition), 2);
       renderCommandEncoder->setFragmentBytes(&cameraPosition, sizeof(cameraPosition), 3);
       
       renderCommandEncoder->setFrontFacingWinding(MTL::WindingCounterClockwise);
       renderCommandEncoder->setCullMode(MTL::CullModeBack);
   //    renderCommandEncoder->setTriangleFillMode(MTL::TriangleFillModeLines);
       renderCommandEncoder->setRenderPipelineState(metalRenderPSO);
       renderCommandEncoder->setDepthStencilState(depthStencilState);
       renderCommandEncoder->setVertexBuffer(cubeVertexBuffer, 0, 0);
       renderCommandEncoder->setVertexBuffer(cubeTransformationBuffer, 0, 1);
       MTL::PrimitiveType typeTriangle = MTL::PrimitiveTypeTriangle;
       NS::UInteger vertexStart = 0;
       NS::UInteger vertexCount = 36;
   //    renderCommandEncoder->setFragmentTexture(grassTexture->texture, 0);

       renderCommandEncoder->drawPrimitives(typeTriangle, vertexStart, vertexCount);
       
       matrix_float4x4 scaleMatrix = matrix4x4_scale(0.5f, 0.5f, 0.5f);
       translationMatrix = matrix4x4_translation(lightPosition.xyz);
       
       modelMatrix = simd_mul(translationMatrix, scaleMatrix);
           
       renderCommandEncoder->setRenderPipelineState(metalLightSourceRenderPSO);

       transformationData = { modelMatrix, viewMatrix, perspectiveMatrix };
       memcpy(lightTransformationBuffer->contents(), &transformationData, sizeof(transformationData));
       
       renderCommandEncoder->setVertexBuffer(lightVertexBuffer, 0, 0);
       renderCommandEncoder->setVertexBuffer(lightTransformationBuffer, 0, 1);

       renderCommandEncoder->setFragmentBytes(&lightColor, sizeof(lightColor), 0);
       renderCommandEncoder->drawPrimitives(typeTriangle, vertexStart, vertexCount);
}



void MTLEngine:: frameBufferSizeCallback(GLFWwindow* window, int width, int height){
    MTLEngine* engine = (MTLEngine*)glfwGetWindowUserPointer(window);
    engine->resizeFrameBuffer(width, height);
}

void MTLEngine::resizeFrameBuffer(int width, int height) {
    metalLayer.drawableSize = CGSizeMake(width, height);
    // Deallocate the textures if they have been created
    if (msaaRenderTargetTexture) {
        msaaRenderTargetTexture->release();
        msaaRenderTargetTexture = nullptr;
    }
    if (depthTexture) {
        depthTexture->release();
        depthTexture = nullptr;
    }
    createDepthAndMSAATextures();
    metalDrawable = (__bridge CA::MetalDrawable*)[metalLayer nextDrawable];
    updateRenderPassDescriptor();
}
