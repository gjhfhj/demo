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
    printf("------------------------------Engine to init----------------------------------\n");
    initDevice();
    initWindow();
    createSquare();
    createDefaultLibrary();
    createCommandQueue();
    createRenderPipeline();
    
    printf("------------------------Engine inited(the next: run)--------------------------\n");
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
    printf("-----------------------------Cleanup the memory--------------------------------\n");
    
    glfwTerminate();
    metalDevice->release();
    
    printf("----------------------------------Done-----------------------------------------\n");
}

void MTLEngine::initDevice(){
    metalDevice = MTL::CreateSystemDefaultDevice();
    camera = new Camera();
    printf("metalDevice inited.\n");
}

void MTLEngine::initWindow() {
    glfwInit();
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    glfwWindow = glfwCreateWindow(800, 600, "Metal Engine", NULL, NULL);
    
    if (!glfwWindow) {
        glfwTerminate();
        exit(EXIT_FAILURE);
    }
    
    glfwSetWindowUserPointer(glfwWindow, this);
    glfwSetFramebufferSizeCallback(glfwWindow, frameBufferSizeCallback);
    // 设置键盘回调函数
    glfwSetKeyCallback(glfwWindow, keyCallback);  // 这里注册了键盘回调函数
    glfwSetCursorPosCallback(glfwWindow, mouseCallback);
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
    // Make sure to change working directory to this project
    // directory via Product -> Scheme -> Edit Scheme -> Run -> Options
    myTexture = new Texture("assets/porch.png", metalDevice);
    
    float ratio = (float)myTexture->width / myTexture->height;  //两个整数相除会执行整数除法。
    //默认ratio处为1，但为了匹配texture的比例，为此适配
    VertexData squareVertices[] {
        {{-ratio, -1.0,  0.0, 1.0f}, {0.0f, 0.0f}},   // leftbottom
        {{-ratio,  1.0,  0.0, 1.0f}, {0.0f, 1.0f}},   // lefttop
        {{ ratio,  1.0,  0.0, 1.0f}, {1.0f, 1.0f}},   // righttop
        {{-ratio, -1.0,  0.0, 1.0f}, {0.0f, 0.0f}},   // leftbottom
        {{ ratio,  1.0,  0.0, 1.0f}, {1.0f, 1.0f}},   // righttop
        {{ ratio, -1.0,  0.0, 1.0f}, {1.0f, 0.0f}}    // rightbottom
    };
    
    squareVertexBuffer = metalDevice->newBuffer(&squareVertices, sizeof(squareVertices), MTL::ResourceStorageModeShared);
    transformationBuffer = metalDevice->newBuffer(sizeof(TransformationData), MTL::ResourceStorageModeShared);
    
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
    printf("\n\tSending render command:\n");
    
    metalCommandBuffer = metalCommandQueue->commandBuffer();
    
    printf("\t\t* created metalCommandBuffer.\n");

    MTL::RenderPassDescriptor* renderPassDescriptor = MTL::RenderPassDescriptor::alloc()->init();
    
    printf("\t\t* created renderPassDescriptor.\n");
    
    MTL::RenderPassColorAttachmentDescriptor* cd = renderPassDescriptor->colorAttachments()->object(0); //创建渲染通道描述符，定义渲染目标。
    
    printf("\t\t* 创建渲染通道描述符，定义渲染目标.\n");
    
    cd->setTexture(metalDrawable->texture());   //设置渲染目标为 metalDrawable 的纹理。
    
    printf("\t\t* 设置渲染目标为 metalDrawable 的纹理.\n");
    
    cd->setLoadAction(MTL::LoadActionClear);    //设置加载操作为清除。
    
    printf("\t\t* 设置加载操作为清除.\n");
    
    cd->setClearColor(MTL::ClearColor(173.0f/255.0f, 214.0f/255.0f, 255.0f/255.0f, 1.0));  //设置清除颜色。
    
    printf("\t\t* 设置清除颜色.\n");
    
    cd->setStoreAction(MTL::StoreActionStore);
    
    printf("\t\t* StoreActionStore.\n");

    MTL::RenderCommandEncoder* renderCommandEncoder = metalCommandBuffer->renderCommandEncoder(renderPassDescriptor);   //创建渲染命令编码器。
    
    printf("\t\t* 创建渲染命令编码器.\n");
    
    encodeRenderCommand(renderCommandEncoder);  //编码具体的渲染命令。
    
    printf("（编码完具体的渲染命令）\n");
    
    renderCommandEncoder->endEncoding();    //结束编码。
    
    printf("\t\t* endEncoding\n");

    metalCommandBuffer->presentDrawable(metalDrawable); //将渲染结果显示到屏幕。
    
    printf("\t\t* presented Drawable（将渲染结果显示到屏幕）\n");
    
    metalCommandBuffer->commit();   //提交命令缓冲区。
    
    printf("\t\t* committed commandBuffer（提交命令缓冲区）\n");
    
    metalCommandBuffer->waitUntilCompleted();   //等待渲染完成（调试用，正式应用中可移除）。
    

    renderPassDescriptor->release();
    
    printf("\t\t* renderPassDescriptor released\t\n");
}

void MTLEngine::encodeRenderCommand(MTL::RenderCommandEncoder* renderCommandEncoder) {
    printf("\tEncoding render command:\n");
        
    matrix_float4x4 translationMatrix = matrix4x4_translation(0,0,-2.0);
    
    printf("\t\t* created translationMatrix\n");
    
    float angle = 0;
    matrix_float4x4 rotationMatrix = matrix4x4_rotation(angle, 1, 0, 0);
    
    matrix_float4x4 modelMatrix = simd_mul(translationMatrix, rotationMatrix);
    
    matrix_float4x4 viewMatrix = camera->getViewMatrix();
    
    printf("\t\t* created viewMatrix\n");
    
    matrix_float4x4 metalMatrix = camera->getMetalMatrix();
    
    printf("\t\t* created metalMatrix\n");

    TransformationData transformationData = { modelMatrix, viewMatrix, metalMatrix };
    
    printf("\t\t* done transformationData\n");
    
    memcpy(transformationBuffer->contents(), &transformationData, sizeof(transformationData));
    
    printf("\t\t* done memcpy\n");

    renderCommandEncoder->setRenderPipelineState(metalRenderPSO);
    renderCommandEncoder->setVertexBuffer(squareVertexBuffer, 0, 0);
    renderCommandEncoder->setVertexBuffer(transformationBuffer, 0, 1);
    MTL::PrimitiveType typeTriangle = MTL::PrimitiveTypeTriangle;
    NS::UInteger vertexStart = 0;
    NS::UInteger vertexCount = 6;
    renderCommandEncoder->setFragmentTexture(myTexture->texture, 0);
    renderCommandEncoder->drawPrimitives(typeTriangle, vertexStart, vertexCount);

    printf("Encoded");
}


void MTLEngine:: frameBufferSizeCallback(GLFWwindow* window, int width, int height){
    MTLEngine* engine = (MTLEngine*)glfwGetWindowUserPointer(window);
    engine->resizeFrameBuffer(width, height);
}

void MTLEngine::resizeFrameBuffer(int width, int height){
    metalLayer.drawableSize = CGSizeMake(width, height);
}

void MTLEngine::keyCallback(GLFWwindow* window, int key, int scancode, int action, int mods) {
    MTLEngine*  engine = (MTLEngine*)glfwGetWindowUserPointer(window);
    float speed = 0.1f; // 移动速度
    static float xTemp = 400.0f, yTemp = 300.0f;
    if (action == GLFW_PRESS || action == GLFW_REPEAT) {
        if (key == GLFW_KEY_Q) {
            // 按下 Q 键时，退出程序
            printf("Q key pressed, exiting...\n");
            glfwSetWindowShouldClose(window, GLFW_TRUE);  // 设置窗口关闭标志
        }
        if (key == GLFW_KEY_W) engine->camera->setP(engine->camera->getP() + speed * engine->camera->getF()); // 前进
        if (key == GLFW_KEY_S) engine->camera->setP(engine->camera->getP() - speed * engine->camera->getF()); // 后退
        if (key == GLFW_KEY_A) engine->camera->setP(engine->camera->getP() - speed * engine->camera->getR());   // 左移
        if (key == GLFW_KEY_D) engine->camera->setP(engine->camera->getP() + speed * engine->camera->getR());   // 右移
        if (key == GLFW_KEY_SPACE) engine->camera->setP(engine->camera->getP() + speed * simd::float3{0,1,0});  // 上升
        if (key == GLFW_KEY_LEFT_CONTROL) engine->camera->setP(engine->camera->getP() - speed * simd::float3{0,1,0});  // 下降
        if (key == GLFW_KEY_UP) engine->camera->updateOrientation(xTemp,yTemp--);
        if (key == GLFW_KEY_DOWN) engine->camera->updateOrientation(xTemp,yTemp++);
        if (key == GLFW_KEY_LEFT) engine->camera->updateOrientation(xTemp--,yTemp);
        if (key == GLFW_KEY_RIGHT) engine->camera->updateOrientation(xTemp++,yTemp);

    }
}

void MTLEngine::mouseCallback(GLFWwindow* window, double xpos, double ypos) {
    MTLEngine* engine = static_cast<MTLEngine*>(glfwGetWindowUserPointer(window));
    if (engine && engine->camera) {
        engine->camera->updateOrientation(xpos, ypos);
    }
}


