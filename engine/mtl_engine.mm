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

enum Mode { kModeNormal, kModeScanFrag, kModeScnaComput };
Mode currentMode = kModeScanFrag;

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
    createScanFragmentPipeline();
    createDepthAndMSAATextures();
    createOffscreenTextures();
    createOffscreenPassDescriptor();
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
    
    //只是在这里创建了一个深度测试/写入的测试，非属于任何MTLRenderPipelineState对象。
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

void MTLEngine::createScanFragmentPipeline() {
    MTL::Function* vertexFunc = metalDefaultLibrary->newFunction(NS::String::string("scanVertex", NS::ASCIIStringEncoding));
    assert(vertexFunc);
    MTL::Function* fragmentScanFunc = metalDefaultLibrary->newFunction(NS::String::string("fragmentScan", NS::ASCIIStringEncoding));
    assert(fragmentScanFunc);

    auto desc = MTL::RenderPipelineDescriptor::alloc()->init();
    desc->setVertexFunction(vertexFunc);
    desc->setFragmentFunction(fragmentScanFunc);
    assert(desc);
    
    desc->colorAttachments()->object(0)->setPixelFormat((MTL::PixelFormat)metalLayer.pixelFormat);
    desc->setSampleCount(1);
    desc->setLabel(NS::String::string("Scan Fragment Pipeline", NS::ASCIIStringEncoding));
//    desc->setDepthAttachmentPixelFormat(MTL::PixelFormatDepth32Float);

    NS::Error* error = nullptr;
    metalScanPSO = metalDevice->newRenderPipelineState(desc, &error);
    if (!metalScanPSO) {
        std::cerr << error->localizedDescription() << "\n";
        std::exit(1);
    }

    desc->release();
    vertexFunc->release();
    fragmentScanFunc->release();
}

void MTLEngine::createScanComputePipeline() {
    MTL::Function* computeFunc = metalDefaultLibrary->newFunction(NS::String::string("computeScan", NS::ASCIIStringEncoding));
    NS::Error* error;
    metalScanCPSO = metalDevice->newComputePipelineState(computeFunc, &error);
    computeFunc->release();

}

void MTLEngine::createDepthAndMSAATextures() {
    //以下的几个Textures值时通过“ metalDevice->newTexture( sthDescriptor )”创建了一个存储壳子（显存/系统内存块），但并无内容
    
    
    MTL::TextureDescriptor* msaaTextureDescriptor = MTL::TextureDescriptor::alloc()->init();
    msaaTextureDescriptor->setTextureType(MTL::TextureType2DMultisample);
    msaaTextureDescriptor->setPixelFormat(MTL::PixelFormatBGRA8Unorm);
    msaaTextureDescriptor->setWidth(metalLayer.drawableSize.width);
    msaaTextureDescriptor->setHeight(metalLayer.drawableSize.height);
    msaaTextureDescriptor->setSampleCount(sampleCount);
    msaaTextureDescriptor->setUsage(MTL::TextureUsageRenderTarget | MTL::TextureUsageShaderRead);
    
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

void MTLEngine::createOffscreenTextures() {
    // 1. 离屏颜色纹理
    MTL::TextureDescriptor* colorDesc = MTL::TextureDescriptor::alloc()->init();
    colorDesc->setTextureType(MTL::TextureType2DMultisample); //2D多重采样纹理
    colorDesc->setPixelFormat(MTL::PixelFormatBGRA8Unorm);     // 浮点格式存储深度值
    colorDesc->setWidth(metalLayer.drawableSize.width);      // 宽度
    colorDesc->setHeight(metalLayer.drawableSize.height);    // 高度

    colorDesc->setUsage(
        MTL::TextureUsageRenderTarget    // 可作为渲染目标
        | MTL::TextureUsageShaderRead);  // 可作为着色器读取
    colorDesc->setStorageMode(MTL::StorageModePrivate);
    colorDesc->setSampleCount(sampleCount);
    sceneMSAATexture = metalDevice->newTexture(colorDesc);
    colorDesc->release();
    
    
    MTL::TextureDescriptor* resolvedColorDesc = MTL::TextureDescriptor::alloc()->init();
    resolvedColorDesc->setTextureType(MTL::TextureType2D); //2D多重采样纹理
    resolvedColorDesc->setPixelFormat(MTL::PixelFormatBGRA8Unorm);     // 浮点格式存储深度值
    resolvedColorDesc->setWidth(metalLayer.drawableSize.width);      // 宽度
    resolvedColorDesc->setHeight(metalLayer.drawableSize.height);    // 高度
    resolvedColorDesc->setUsage(MTL::TextureUsageRenderTarget | MTL::TextureUsageShaderRead); // 可渲染和读取
    resolvedColorDesc->setStorageMode(MTL::StorageModeShared);
    sceneTargetColorTexture = metalDevice->newTexture(resolvedColorDesc);
    resolvedColorDesc->release();
}

void MTLEngine::createRenderPassDescriptor() {
    //pass的过程
    
    // 1. 先init一个Descriptor
    renderPassDescriptor = MTL::RenderPassDescriptor::alloc()->init();
    
    // 2. 获取颜色和深度附件描述符
    MTL::RenderPassColorAttachmentDescriptor* colorAttachment = renderPassDescriptor->colorAttachments()->object(0);
    MTL::RenderPassDepthAttachmentDescriptor* depthAttachment = renderPassDescriptor->depthAttachment();

    // ===== Color Attachment 设置 =====
    // 2.1 指定多采样渲染目标（MSAA 中间缓冲）
    colorAttachment->setTexture(msaaRenderTargetTexture); //渲染时，所有的片元输出先写入这个多采样纹理（sampleCount > 1）的中间缓冲。
    
    // 2.2 在 Pass 开始前清除并填充背景色
    colorAttachment->setLoadAction(MTL::LoadActionClear); //在draw之前清除
    colorAttachment->setClearColor(MTL::ClearColor(41.0f/255.0f, 42.0f/255.0f, 48.0f/255.0f, 1.0)); // 并置为同一指定颜色背景

    // 2.3 Pass 结束时，将 MSAA 缓冲解析到最终可呈现纹理
    colorAttachment->setResolveTexture(sceneTargetColorTexture); //pass结束后将MSAA中间缓冲“解析resolve”为单采样并写入此（屏幕最终输出的纹理）
    colorAttachment->setStoreAction(MTL::StoreActionStoreAndMultisampleResolve); //渲染结束时，不仅要保留 MSAA 缓冲的数据，还要自动把它 resolve                                                                                    到上面指定的单采样纹理。（metalDrawable吗？)

    // ===== Depth Attachment 设置 =====
    // 3.1 指定 MSAA 深度缓冲
    depthAttachment->setTexture(depthTexture); //深度测试和深度写入都发生在这个多采样深度缓冲上。
          
    // 3.2 在 Pass 开始前清除深度缓冲
    depthAttachment->setLoadAction(MTL::LoadActionClear); //Pass开始时清除深度缓冲
    depthAttachment->setClearDepth(1.0); //并把所有像素深度设为 1.0（最远）。
    
    // 3.3 Pass 结束时，将 MSAA 深度解析到指定深度纹理
    depthAttachment->setResolveTexture(resolvedDepthTexture); // Pass结束后，再把多采样深度解析道resolvedDepthTexture里
    depthAttachment->setStoreAction(MTL::StoreActionStoreAndMultisampleResolve);  // 解析多重采样数据
    
    
    //然后在每一帧调用“auto encoder = commandBuffer->renderCommandEncoder(renderPassDescriptor);“时，
    //GPU 会根据这份描述：
    // 1.用 LoadActionClear 清空 color/depth MSAA 缓冲。
    // 2.执行所有 draw 调用，写 color 到 msaaRenderTargetTexture，写 depth 到 depthTexture。
    // 3.Pass 结束时，自动把 MSAA color／depth 各自 resolve（多采样合并）到单采样目标纹理。
    
}

void MTLEngine::updateRenderPassDescriptor() {
    renderPassDescriptor->colorAttachments()->object(0)->setTexture(msaaRenderTargetTexture);
    renderPassDescriptor->colorAttachments()->object(0)->setResolveTexture(metalDrawable->texture());
    renderPassDescriptor->depthAttachment()->setTexture(depthTexture);
    renderPassDescriptor->depthAttachment()->setResolveTexture(resolvedDepthTexture);
}

void MTLEngine::createOffscreenPassDescriptor() {
    // pass过程
    // 1. 分配 RenderPassDescriptor
    offscreenPassDesc = MTL::RenderPassDescriptor::alloc()->init();

    // ===== 离屏色附件设置 =====
    auto colorAtt = offscreenPassDesc->colorAttachments()->object(0);
    // 1.1 绑定多采样场景渲染目标
    colorAtt->setTexture(metalDrawable->texture());
    // 1.2 保留以前渲染结果（load），并指定清除色（可选，仅在LoadAction为Clear时生效）
    colorAtt->setLoadAction(MTL::LoadActionClear);
    colorAtt->setClearColor({0.5,0.5,0.5,1});
   
    // 1.3 Pass 结束时解析 MSAA，并写入最终输出纹理
//    colorAtt->setResolveTexture(resolvedDepthTexture);
//    colorAtt->setStoreAction(MTL::StoreActionMultisampleResolve);


    //这里renderpass相当于onscreenPass，它的目标为metalDrawable，下一帧就丢掉。但offscreenPass用来后期特效什么的，它的生命周期在一整帧内都有效，可以安全地用来做后处理或 CPU 读取。用来做一些视觉效果之类的。
    // ===== 离屏深度附件设置 ===== 直接写到你已有的 resolveDepthTexture
//    auto depthAtt = offscreenPassDesc->depthAttachment();
    
    // 2.1 绑定 MSAA 深度缓冲
//    depthAtt->setTexture(resolvedDepthTexture); //写入深度值
    
    // 2.2 指定以 LoadActionLoad 开始，下一行 ClearDepth 只在 LoadActionClear 时生效
    //以下两代码在offEnc = commandBuffer->renderCommandEncoder(offscreenPassDesc时先把depthTexture清为1
//    depthAtt->setLoadAction(MTL::LoadActionLoad);
//    depthAtt->setClearDepth(0.0);
    
    // 2.3 若需将 MSAA 深度解析到单采样纹理，可启用以下设置
    //以下两代码在offEnc->endEncoding()时把 depthTexture（多重采样 MSAA）上所有样本合并，然后写入同一个 resolvedDepthTexture（单采样）。
//    depthAtt->setResolveTexture(resolvedDepthTexture);
//    depthAtt->setStoreAction(MTL::StoreActionMultisampleResolve); //resolvedDepthTexture 已经是解析后的纹理，这种配置可能是多余的或不正确的。
    
    
    
    /*
     * 离屏 Pass 与 Onscreen Pass 不同之处：
     * - Onscreen Pass 直接输出到屏幕背缓冲，每帧提交即丢弃；
     * - Offscreen Pass 的附件在整个帧内有效，可用于后处理、CPU 读取等效果。
     */
}

void MTLEngine::updateOffscreenPassDescriptor() {
    offscreenPassDesc->colorAttachments()->object(0)->setTexture(metalDrawable->texture());
}

void MTLEngine::postProcessPass() {
    // Post-Process Pass
    MTL::RenderPassDescriptor* ppDesc = MTL::RenderPassDescriptor::alloc()->init();
    ppDesc->colorAttachments()->object(0)->setTexture(metalDrawable->texture());
    ppDesc->colorAttachments()->object(0)->setLoadAction(MTL::LoadActionClear);
    ppDesc->colorAttachments()->object(0)->setStoreAction(MTL::StoreActionStore);
    ppDesc->colorAttachments()->object(0)->setClearColor({0,0,0,1});

    auto ppEnc = metalCommandBuffer->renderCommandEncoder(ppDesc);
    ppEnc->setRenderPipelineState(metalScanPSO);

    // 绑定场景颜色纹理到纹理槽 0
    ppEnc->setFragmentTexture(sceneMSAATexture, 0);
    // 绑定深度纹理到槽 1
    ppEnc->setFragmentTexture(resolvedDepthTexture, 1);
    // 传入扫描参数到 buffer 4
    float t = glfwGetTime();
    ppEnc->setFragmentBytes(&t, sizeof(float), 4);

    // 画一个全屏三角形（vertex_id=0,1,2）
    ppEnc->drawPrimitives(MTL::PrimitiveTypeTriangle, (NS::UInteger)0, (NS::UInteger)3);
    ppEnc->endEncoding();
    ppDesc->release();

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
    
//    updateOffscreenPassDescriptor();
//    auto offEnc = metalCommandBuffer->renderCommandEncoder(offscreenPassDesc);
//    //scanPSO
////    float scanTime = fmod(glfwGetTime(), 1.0f);  // 周期 1 秒
//    offEnc->setRenderPipelineState(metalScanPSO);
////    offEnc->setDepthStencilState(depthStencilState);
//    offEnc->setFragmentTexture(sceneTargetColorTexture, 0);
//    offEnc->setFragmentTexture(resolvedDepthTexture, 1);
//    float speed = 0.2f;
//    struct ScanUniforms {
//        float uProgress, bandWidth, intensity;
//        float4 highlightColor[3];
//    } scanUni;
//    // 每帧更新
//    scanUni.uProgress     = glfwGetTime() * speed;  // speed 决定扫描速度
//    scanUni.bandWidth     = 0.05;                   // 试着 0.01~0.05
//    scanUni.intensity     = 1.2;                    // 1.0~2.0
//    scanUni.highlightColor[0] = 0.8; // R
//    scanUni.highlightColor[1] = 0.2; // G
//    scanUni.highlightColor[2] = 0.2; // B
//    offEnc->setFragmentBytes(&scanUni, sizeof(scanUni), 4);
////    offEnc->setFragmentBytes(&scanTime, sizeof(scanTime), 4);
//    offEnc->drawPrimitives(MTL::PrimitiveTypeTriangle, (NS::UInteger)0, (NS::UInteger)3);
//    offEnc->endEncoding();
    
//    copyDepthTextureAfterRenderEncodedBeforeSendingCommand();   //在渲染后复制深度纹理为了获取到深度图
    
//    postProcessPass();
    
    metalCommandBuffer->presentDrawable(metalDrawable);
    metalCommandBuffer->commit();
    metalCommandBuffer->waitUntilCompleted();
    
//    writeDepthTexture();
    
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

    renderCommandEncoder->setFrontFacingWinding(MTL::WindingCounterClockwise);
    renderCommandEncoder->setCullMode(MTL::CullModeBack);

    NS::UInteger vertexStart = 0;
    NS::UInteger vertexCount = 36;
    MTL::PrimitiveType typeTriangle = MTL::PrimitiveTypeTriangle;

    //       renderCommandEncoder->setTriangleFillMode(MTL::TriangleFillModeLines);
    //cubePSO
    renderCommandEncoder->setFragmentBytes(&cubeColor, sizeof(cubeColor), 0);
    renderCommandEncoder->setFragmentBytes(&lightColor, sizeof(lightColor), 1);
    renderCommandEncoder->setFragmentBytes(&lightPosition, sizeof(lightPosition), 2);
    renderCommandEncoder->setFragmentBytes(&cameraPosition, sizeof(cameraPosition), 3);
    renderCommandEncoder->setRenderPipelineState(metalRenderPSO);
    renderCommandEncoder->setDepthStencilState(depthStencilState); //此pass中，从drawPrimitives这一画开始调用深度测试写入，只要在同一个Encoder里头就不需要再次set了，尽管欢乐PSO。
    renderCommandEncoder->setVertexBuffer(cubeVertexBuffer, 0, 0);
    renderCommandEncoder->setVertexBuffer(cubeTransformationBuffer, 0, 1);
    //         renderCommandEncoder->setFragmentTexture(grassTexture->texture, 0);
    renderCommandEncoder->drawPrimitives(typeTriangle, vertexStart, vertexCount);

    //lightPSO
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


void MTLEngine::writeDepthTexture() {
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

void MTLEngine::keyCallback(GLFWwindow* window, int key, int scancode, int action, int mods) {
    if (action == GLFW_PRESS) {
        if (key == GLFW_KEY_1) currentMode = kModeNormal;
        else if (key == GLFW_KEY_2) currentMode = kModeScanFrag;
        else if (key == GLFW_KEY_3) currentMode = kModeScnaComput;
    }
}
