//
//  mtl_engine.mm
//  engine
//
//  Created by menji on 2025/2/20.
//

#include "mtl_engine.hpp"

#include <iostream>
// 只导入 std::cerr
using std::cerr;

void MTLEngine::init(){
    printf("-------------------------------Engine to init--------------------------------\n");
    initDevice();
    initWindow();
    
    createSquare();
    createDefaultLibrary();
    createCommandQueue();
    createRenderPipeline();
    
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
    
    if (!glfwWindow) {
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
    
    printf("glfw window inited.\n");
}



void MTLEngine::createSquare() {
    VertexData squareVertices[] {
        {{-0.5, -0.5,  0.5, 1.0f}, {0.0f, 0.0f}},
        {{-0.5,  0.5,  0.5, 1.0f}, {0.0f, 1.0f}},
        {{ 0.5,  0.5,  0.5, 1.0f}, {1.0f, 1.0f}},
        {{-0.5, -0.5,  0.5, 1.0f}, {0.0f, 0.0f}},
        {{ 0.5,  0.5,  0.5, 1.0f}, {1.0f, 1.0f}},
        {{ 0.5, -0.5,  0.5, 1.0f}, {1.0f, 0.0f}}
    };
    
    squareVertexBuffer = metalDevice->newBuffer(&squareVertices, sizeof(squareVertices), MTL::ResourceStorageModeShared);

    // Make sure to change working directory to this project
    // directory via Product -> Scheme -> Edit Scheme -> Run -> Options
    grassTexture = new Texture("assets/big_creeper_face.png", metalDevice);
    
    printf("square created.\n");
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
    printf("renderPipeline creating:\n");
    
    MTL::Function* vertexShader = metalDefaultLibrary->newFunction(NS::String::string("vertexShader", NS::ASCIIStringEncoding));
    assert(vertexShader); //assert() 检查 参数 是否为空，如果为空，表示创建管线描述符失败，会中断程序。
    
    printf("\t-------\tvertexShader created\n");
    
    MTL::Function* fragmentShader = metalDefaultLibrary->newFunction(NS::String::string("fragmentShader", NS::ASCIIStringEncoding));
    assert(fragmentShader);
    
    printf("\t-------\tfragmentShader created\n");
    
    MTL::RenderPipelineDescriptor* renderPipelineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();
    renderPipelineDescriptor->setLabel(NS::String::string("Square Rendering Pipeline", NS::ASCIIStringEncoding));
    renderPipelineDescriptor->setVertexFunction(vertexShader);
    renderPipelineDescriptor->setFragmentFunction(fragmentShader);
    assert(renderPipelineDescriptor);
    
    printf("\t-------\trenderPipelineDescriptor created and configured\n");
    
    MTL::PixelFormat pixelFormat = (MTL::PixelFormat)metalLayer.pixelFormat;
    renderPipelineDescriptor->colorAttachments()->object(0)->setPixelFormat(pixelFormat);
    
    printf("\t-------\tpixelFormat setted on renderPipelineDescriptor\n");
    
    NS::Error* error;
    metalRenderPSO = metalDevice->newRenderPipelineState(renderPipelineDescriptor, &error);
    
    printf("\t-------\tset Pipeline State Object(PSO)\n");
    
    renderPipelineDescriptor->release();
    
    printf("renderPipeline created.\n");
}


void MTLEngine::draw(){

    printf("Draw:\t");
    sendRenderCommand();
    
}

void MTLEngine::sendRenderCommand() {
    printf("Sending render command.\t");
    
    metalCommandBuffer = metalCommandQueue->commandBuffer();

    MTL::RenderPassDescriptor* renderPassDescriptor = MTL::RenderPassDescriptor::alloc()->init();
    MTL::RenderPassColorAttachmentDescriptor* cd = renderPassDescriptor->colorAttachments()->object(0);
    cd->setTexture(metalDrawable->texture());
    cd->setLoadAction(MTL::LoadActionClear);
    cd->setClearColor(MTL::ClearColor(41.0f/255.0f, 42.0f/255.0f, 48.0f/255.0f, 1.0));
    cd->setStoreAction(MTL::StoreActionStore);

    MTL::RenderCommandEncoder* renderCommandEncoder = metalCommandBuffer->renderCommandEncoder(renderPassDescriptor);
    encodeRenderCommand(renderCommandEncoder);
    renderCommandEncoder->endEncoding();

    metalCommandBuffer->presentDrawable(metalDrawable);
    metalCommandBuffer->commit();
    metalCommandBuffer->waitUntilCompleted();

    renderPassDescriptor->release();
    
    printf("sended\n");
}

void MTLEngine::encodeRenderCommand(MTL::RenderCommandEncoder* renderCommandEncoder) {
    printf("Encoding render command.\t");
    
    renderCommandEncoder->setRenderPipelineState(metalRenderPSO);
    renderCommandEncoder->setVertexBuffer(squareVertexBuffer, 0, 0);
    MTL::PrimitiveType typeTriangle = MTL::PrimitiveTypeTriangle;
    NS::UInteger vertexStart = 0;
    NS::UInteger vertexCount = 6;
    renderCommandEncoder->setFragmentTexture(grassTexture->texture, 0);
    renderCommandEncoder->drawPrimitives(typeTriangle, vertexStart, vertexCount);

    printf("Encoded\t");
}


void MTLEngine:: frameBufferSizeCallback(GLFWwindow* window, int width, int height){
    MTLEngine* engine = (MTLEngine*)glfwGetWindowUserPointer(window);
    engine->resizeFrameBuffer(width, height);
}

void MTLEngine::resizeFrameBuffer(int width, int height){
    metalLayer.drawableSize = CGSizeMake(width, height);
}

