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
#include <app/PointerEvent.h>
#include <app/WheelEvent.h>
#include <app/KeyboardEvent.h>
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

/**
 * Instance contructor
 */

void* HaxeApp_create() {
    hx::NativeAttach haxeGcScope;
    hx::Native<app::HaxeAppInterface*> app = HaxeApp::create();
    postHaxeExecution();
    return new AppHandle(app);
}

void HaxeApp_release(void* ptr) {
    hx::NativeAttach haxeGcScope;
    AppHandle* appHandle = (AppHandle*) ptr;
    delete appHandle;
}

void HaxeApp_onResize(void* ptr, double width, double height) {
    hx::NativeAttach haxeGcScope;
    AppHandle* appHandle = (AppHandle*) ptr;
    appHandle->haxeRef->onResize(width, height);
    postHaxeExecution();
}

/**
 * Graphics Context Events
 */

void HaxeApp_onGraphicsContextReady(
    void* ptr,
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
    AppHandle* appHandle = (AppHandle*) ptr;
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

void HaxeApp_onGraphicsContextLost(void* ptr) {
    hx::NativeAttach haxeGcScope;
    AppHandle* appHandle = (AppHandle*) ptr;
    appHandle->haxeRef->onGraphicsContextLost();
    postHaxeExecution();
}

void HaxeApp_onDrawFrame(void* ptr, int32_t drawingBufferWidth, int32_t drawingBufferHeight) {
    hx::NativeAttach haxeGcScope;
    AppHandle* appHandle = (AppHandle*) ptr;
    appHandle->haxeRef->onDrawFrame(drawingBufferWidth, drawingBufferHeight);
    postHaxeExecution();
}

/**
 * PointerEvent API
 */

bool HaxeApp_onPointerDown(void* ptr, int32_t pointerId, const char* pointerType, bool isPrimary, int32_t button, int32_t buttons, double x, double y, double width, double height, double pressure, double tangentialPressure, double tiltX, double tiltY, double twist) {
    hx::NativeAttach haxeGcScope;
    AppHandle* appHandle = (AppHandle*) ptr;
    HX_JUST_GC_STACKFRAME
    // construct a PointerEvent object
    app::PointerEvent pointerEvent = app::PointerEvent_obj::__alloc(HX_CTX, pointerId, ::String(pointerType), isPrimary, button, buttons, x, y, width, height, pressure, tangentialPressure, tiltX, tiltY, twist);
    bool preventDefault = appHandle->haxeRef->onPointerDown(pointerEvent);
    postHaxeExecution();
    return preventDefault;
}

bool HaxeApp_onPointerMove(void* ptr, int32_t pointerId, const char* pointerType, bool isPrimary, int32_t button, int32_t buttons, double x, double y, double width, double height, double pressure, double tangentialPressure, double tiltX, double tiltY, double twist) {
    hx::NativeAttach haxeGcScope;
    AppHandle* appHandle = (AppHandle*) ptr;
    HX_JUST_GC_STACKFRAME
    // construct a PointerEvent object
    app::PointerEvent pointerEvent = app::PointerEvent_obj::__alloc(HX_CTX, pointerId, ::String(pointerType), isPrimary, button, buttons, x, y, width, height, pressure, tangentialPressure, tiltX, tiltY, twist);
    bool preventDefault = appHandle->haxeRef->onPointerMove(pointerEvent);
    postHaxeExecution();
    return preventDefault;
}

bool HaxeApp_onPointerUp(void* ptr, int32_t pointerId, const char* pointerType, bool isPrimary, int32_t button, int32_t buttons, double x, double y, double width, double height, double pressure, double tangentialPressure, double tiltX, double tiltY, double twist) {
    hx::NativeAttach haxeGcScope;
    AppHandle* appHandle = (AppHandle*) ptr;
    HX_JUST_GC_STACKFRAME
    // construct a PointerEvent object
    app::PointerEvent pointerEvent = app::PointerEvent_obj::__alloc(HX_CTX, pointerId, ::String(pointerType), isPrimary, button, buttons, x, y, width, height, pressure, tangentialPressure, tiltX, tiltY, twist);
    bool preventDefault = appHandle->haxeRef->onPointerUp(pointerEvent);
    postHaxeExecution();
    return preventDefault;
}

bool HaxeApp_onPointerCancel(void* ptr, int32_t pointerId, const char* pointerType, bool isPrimary, int32_t button, int32_t buttons, double x, double y, double width, double height, double pressure, double tangentialPressure, double tiltX, double tiltY, double twist) {
    hx::NativeAttach haxeGcScope;
    AppHandle* appHandle = (AppHandle*) ptr;
    HX_JUST_GC_STACKFRAME
    // construct a PointerEvent object
    app::PointerEvent pointerEvent = app::PointerEvent_obj::__alloc(HX_CTX, pointerId, ::String(pointerType), isPrimary, button, buttons, x, y, width, height, pressure, tangentialPressure, tiltX, tiltY, twist);
    bool preventDefault = appHandle->haxeRef->onPointerCancel(pointerEvent);
    postHaxeExecution();
    return preventDefault;
}

/**
 * Mouse wheel and trackpad scroll event
 */
bool HaxeApp_onWheel(void* ptr, double deltaX, double deltaY, double deltaZ, double x, double y, bool altKey, bool ctrlKey, bool metaKey, bool shiftKey) {
    hx::NativeAttach haxeGcScope;
    AppHandle* appHandle = (AppHandle*) ptr;
    HX_JUST_GC_STACKFRAME
    app::WheelEvent wheelEvent = app::WheelEvent_obj::__alloc(HX_CTX, deltaX, deltaY, deltaZ, x, y, altKey, ctrlKey, metaKey, shiftKey);
    bool preventDefault = appHandle->haxeRef->onWheel(wheelEvent);
    postHaxeExecution();
    return preventDefault;
}

/**
 * Keyboard events
 */
bool HaxeApp_onKeyDown(void* ptr, const char* key, const char* code, KeyLocation location, bool altKey, bool ctrlKey, bool metaKey, bool shiftKey, bool hasFocus) {
    hx::NativeAttach haxeGcScope;
    AppHandle* appHandle = (AppHandle*) ptr;
    HX_JUST_GC_STACKFRAME
    app::KeyboardEvent keyboardEvent = app::KeyboardEvent_obj::__alloc(HX_CTX, ::String(key), ::String(code), (int)location, altKey, ctrlKey, metaKey, shiftKey);
    bool preventDefault = appHandle->haxeRef->onKeyDown(keyboardEvent, hasFocus);
    postHaxeExecution();
    return preventDefault;
}

bool HaxeApp_onKeyUp(void* ptr, const char* key, const char* code, KeyLocation location, bool altKey, bool ctrlKey, bool metaKey, bool shiftKey, bool hasFocus) {
    hx::NativeAttach haxeGcScope;
    AppHandle* appHandle = (AppHandle*) ptr;
    HX_JUST_GC_STACKFRAME
    app::KeyboardEvent keyboardEvent = app::KeyboardEvent_obj::__alloc(HX_CTX, ::String(key), ::String(code), (int)location, altKey, ctrlKey, metaKey, shiftKey);
    bool preventDefault = appHandle->haxeRef->onKeyUp(keyboardEvent, hasFocus);
    postHaxeExecution();
    return preventDefault;
}

/**
 * Life-cycle events
 */
void HaxeApp_onActivate(void* ptr) {
    hx::NativeAttach haxeGcScope;
    AppHandle* appHandle = (AppHandle*) ptr;
    appHandle->haxeRef->onActivate();
    postHaxeExecution();
}
void HaxeApp_onDeactivate(void* ptr) {
    hx::NativeAttach haxeGcScope;
    AppHandle* appHandle = (AppHandle*) ptr;
    appHandle->haxeRef->onDeactivate();
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