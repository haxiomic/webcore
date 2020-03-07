/**
 * C language wrapper for hxcpp-generated HaxeApp class
 * 
 * `hx::NativeAttach haxeGcScope` marks a stack-scope for the hxcpp garbage collector (sets top and bottom of stack)
 * 
 * The gc top and bottom of stack should be set whenever haxe allocations can occur
 * 
 * See https://groups.google.com/forum/#!topic/haxelang/V-jzaEX7YD8
 * and https://github.com/HaxeFoundation/hxcpp/blob/master/docs/ThreadsAndStacks.md
 * For documentation
 */

#include <stdio.h>

// allows us to interface with the HXCPP generated code
#include <hxcpp.h>

#include "HaxeAppC.h"

// include hxcpp generated classes
#include <app/HaxeApp.h>
#include <app/HaxeAppInterface.h>
#include <webgl/native/GLContext.h>

using namespace app;

struct AppHandle {
    hx::Ref<app::HaxeAppInterface*> haxeRef;
    AppHandle(hx::Native<app::HaxeAppInterface*> app) {
        haxeRef = app;
    }
    ~AppHandle() {
        haxeRef = 0;
    }
};

void postHaxeExecution();

const char* HaxeApp_haxeInitialize(MainThreadTick tickOnMainThread) {
    return HaxeApp::haxeInitialize(tickOnMainThread);
}

bool HaxeApp_isHaxeInitialized() {
    hx::NativeAttach haxeGcScope;
    return HaxeApp::isHaxeInitialized();
}

bool HaxeApp_isEventLoopThreadRunning() {
    hx::NativeAttach haxeGcScope;
    return HaxeApp::isEventLoopThreadRunning();
}

void HaxeApp_tick() {
    hx::NativeAttach haxeGcScope;
    HaxeApp::tick();
    postHaxeExecution();
}

void HaxeApp_startEventLoopThread() {
    hx::NativeAttach haxeGcScope;
    HaxeApp::startEventLoopThread();
}

void HaxeApp_stopEventLoopThread() {
    hx::NativeAttach haxeGcScope;
    HaxeApp::stopEventLoopThread();
}

void HaxeApp_runGc(bool major) {
    hx::NativeAttach haxeGcScope;
    HaxeApp::runGc(major);
}

void* HaxeApp_create() {
    hx::NativeAttach haxeGcScope;

    hx::Native<app::HaxeAppInterface*> app = HaxeApp::create();

    postHaxeExecution();

    return new AppHandle(app);
}

void HaxeApp_release(void* untypedAppHandle) {
    hx::NativeAttach haxeGcScope;

    AppHandle* appHandle = (AppHandle*) untypedAppHandle;
    delete appHandle;
}

void HaxeApp_onResize(void* untypedAppHandle, double width, double height) {
    hx::NativeAttach haxeGcScope;

    AppHandle* appHandle = (AppHandle*) untypedAppHandle;
    appHandle->haxeRef->onResize(width, height);

    postHaxeExecution();
}

void HaxeApp_onGraphicsContextReady(
    void* untypedAppHandle,
    void* contextRef,
    bool alpha,
    bool depth,
    bool stencil,
    bool antialias,
    SetGraphicsContext setGraphicsContext,
    GetContextParamInt32 getDrawingBufferWidth,
    GetContextParamInt32 getDrawingBufferHeight
) {
    hx::NativeAttach haxeGcScope;

    AppHandle* appHandle = (AppHandle*) untypedAppHandle;
    HX_JUST_GC_STACKFRAME
    // create an gl context wrapper (the real context must already be created)
    webgl::native::GLContext gl = webgl::native::GLContext_obj::__alloc(
        HX_CTX,
        contextRef,
        alpha,
        depth,
        stencil,
        antialias,
        setGraphicsContext,
        getDrawingBufferWidth,
        getDrawingBufferHeight
    );
    appHandle->haxeRef->onGraphicsContextReady(gl);

    postHaxeExecution();
}

void HaxeApp_onGraphicsContextLost(void* untypedAppHandle) {
    hx::NativeAttach haxeGcScope;

    AppHandle* appHandle = (AppHandle*) untypedAppHandle;
    appHandle->haxeRef->onGraphicsContextLost();

    postHaxeExecution();
}

void HaxeApp_onDrawFrame(void* untypedAppHandle, int32_t drawingBufferWidth, int32_t drawingBufferHeight) {
    hx::NativeAttach haxeGcScope;

    AppHandle* appHandle = (AppHandle*) untypedAppHandle;
    appHandle->haxeRef->onDrawFrame(drawingBufferWidth, drawingBufferHeight);

    postHaxeExecution();
}

/**
 * Should be called after executing haxe code and before returning to external code
 */
void postHaxeExecution() {
    // it's possible the active graphics context will be changed by external code
    // by setting this variable to null, haxe will make sure the right graphics context is activated before executing any graphics calls in the future
    webgl::native::GLContext_obj::knownCurrentReference = nullptr;

    // after executing haxe code we need to check if new events have been scheduled (and to wake the event loop if so)
    // in the future we should redefine MainLoop to wake the loop automatically
    if (HaxeApp::eventLoopNeedsWake()) HaxeApp::wakeEventLoop();
}