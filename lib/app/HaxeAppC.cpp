/**
 * C language wrapper for hxcpp-generated HaxeApp class
 */

#include <stdio.h>

// allows us to interface with the HXCPP generated code
#include <hxcpp.h>

// include the hxcpp generated HaxeApp class
#include <HaxeApp.h>

#include "HaxeAppC.h"

#include <app/HaxeAppInterface.h>
#include <gluon/webgl/native/GLContext.h>

struct AppHandle {
    hx::Ref<app::HaxeAppInterface*> haxeRef;
    AppHandle(hx::Native<app::HaxeAppInterface*> app) {
        haxeRef = app;
    }
    ~AppHandle() {
        haxeRef = 0;
    }
};

const char* HaxeApp_initialize() {
    return HaxeApp::initialize();
}

HaxeAppHandle* HaxeApp_create() {
    hx::Native<app::HaxeAppInterface*> app = HaxeApp::create();
    return new AppHandle(app);
}

void HaxeApp_release(AppHandle* appHandle) {
    delete appHandle;
}

void HaxeApp_onGraphicsContextReady(AppHandle* appHandle) {
    HX_JUST_GC_STACKFRAME
    // create an gl context wrapper (the real context must already be created)
    gluon::webgl::native::GLContext gl = gluon::webgl::native::GLContext_obj::__alloc(HX_CTX);
    appHandle->haxeRef->onGraphicsContextReady(gl);
}

void HaxeApp_onGraphicsContextLost(AppHandle* appHandle) {
    appHandle->haxeRef->onGraphicsContextLost();
}

void HaxeApp_onDrawFrame(AppHandle* appHandle) {
    appHandle->haxeRef->onDrawFrame();
}