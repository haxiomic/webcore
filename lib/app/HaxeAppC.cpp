/**
 * C language wrapper for hxcpp-generated HaxeApp class
 * 
 * `hx::NativeAttach haxeGcScope` marks a stack-scope for the hxcpp garbage collector (sets top and bottom of stack)
 * 
 * The gc top and bottom of stack should be set whenever haxe allocations can occur
 * 
 * After executing haxe code we need to check if new events have been scheduled (and to wake the event loop if so). In the future we should redefine MainLoop to wake the loop automatically
 * 
 * See https://groups.google.com/forum/#!topic/haxelang/V-jzaEX7YD8
 * and https://github.com/HaxeFoundation/hxcpp/blob/master/docs/ThreadsAndStacks.md
 * For documentation
 */

#include <stdio.h>

// allows us to interface with the HXCPP generated code
#include <hxcpp.h>

// include the hxcpp generated HaxeApp class
#include <HaxeApp.h>

#include "HaxeAppC.h"

#include <app/HaxeAppInterface.h>
#include <webgl/native/GLContext.h>

struct AppHandle {
    hx::Ref<app::HaxeAppInterface*> haxeRef;
    AppHandle(hx::Native<app::HaxeAppInterface*> app) {
        haxeRef = app;
    }
    ~AppHandle() {
        haxeRef = 0;
    }
};

const char* HaxeApp_initialize(MainThreadTick tickOnMainThread, SelectGraphicsContext selectGraphicsContext) {
    return HaxeApp::initialize(tickOnMainThread, selectGraphicsContext);
}

void HaxeApp_tick() {
    hx::NativeAttach haxeGcScope;

    HaxeApp::tick();
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

    if (HaxeApp::eventLoopNeedsWake()) HaxeApp::wakeEventLoop();

    return new AppHandle(app);
}

void HaxeApp_release(void* untypedAppHandle) {
    hx::NativeAttach haxeGcScope;

    AppHandle* appHandle = (AppHandle*) untypedAppHandle;
    delete appHandle;
}

void HaxeApp_onGraphicsContextReady(void* untypedAppHandle, void* contextRef) {
    hx::NativeAttach haxeGcScope;

    HaxeApp::setGlobalGraphicsContext(contextRef);

    AppHandle* appHandle = (AppHandle*) untypedAppHandle;
    HX_JUST_GC_STACKFRAME
    // create an gl context wrapper (the real context must already be created)
    webgl::native::GLContext gl = webgl::native::GLContext_obj::__alloc(HX_CTX);
    appHandle->haxeRef->onGraphicsContextReady(gl);

    if (HaxeApp::eventLoopNeedsWake()) HaxeApp::wakeEventLoop();
}

void HaxeApp_onGraphicsContextLost(void* untypedAppHandle) {
    hx::NativeAttach haxeGcScope;

    HaxeApp::setGlobalGraphicsContext(NULL);

    AppHandle* appHandle = (AppHandle*) untypedAppHandle;
    appHandle->haxeRef->onGraphicsContextLost();

    if (HaxeApp::eventLoopNeedsWake()) HaxeApp::wakeEventLoop();
}

void HaxeApp_onGraphicsContextResize(void* untypedAppHandle, int drawingBufferWidth, int drawingBufferHeight, double displayPixelRatio) {
    hx::NativeAttach haxeGcScope;

    AppHandle* appHandle = (AppHandle*) untypedAppHandle;
    appHandle->haxeRef->onGraphicsContextResize(drawingBufferWidth, drawingBufferHeight, displayPixelRatio);

    if (HaxeApp::eventLoopNeedsWake()) HaxeApp::wakeEventLoop();
}

void HaxeApp_onDrawFrame(void* untypedAppHandle) {
    hx::NativeAttach haxeGcScope;

    AppHandle* appHandle = (AppHandle*) untypedAppHandle;
    appHandle->haxeRef->onDrawFrame();

    if (HaxeApp::eventLoopNeedsWake()) HaxeApp::wakeEventLoop();
}