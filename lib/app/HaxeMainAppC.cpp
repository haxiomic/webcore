/**
 * C language wrapper for hxcpp-generated AppInterface class
 */

#include <stdio.h>
// hx/Native.h allows us to interface with the HXCPP generated code
#include <hxcpp.h>

// include the hxcpp generated AppInterface class
#include <HaxeMainApp.h>

#include "HaxeMainAppC.h"

#include <app/AppInterface.h>
#include <gluon/webgl/native/GLContext.h>

struct AppHandle {
    hx::Ref<app::AppInterface*> haxeRef;
    AppHandle(hx::Native<app::AppInterface*> app) {
        haxeRef = app;
    }
    ~AppHandle() {
        haxeRef = 0;
    }
};

const char* HaxeMainApp_haxeInitializeAndRun() {
    return HaxeMainApp::haxeInitializeAndRun();
}

AppInterfaceHandle* HaxeMainApp_createInstance() {
    hx::Native<app::AppInterface*> app = HaxeMainApp::createInstance();
    return new AppHandle(app);
}

void HaxeMainApp_releaseInstance(AppHandle* appHandle) {
    delete appHandle;
}

void AppInterface_onGraphicsContextReady(AppHandle* appHandle) {
    HX_JUST_GC_STACKFRAME
    // create an gl context wrapper (the real context must already be created)
    gluon::webgl::native::GLContext gl = gluon::webgl::native::GLContext_obj::__alloc(HX_CTX);
    appHandle->haxeRef->onGraphicsContextReady(gl);
}

void AppInterface_onGraphicsContextLost(AppHandle* appHandle) {
    appHandle->haxeRef->onGraphicsContextLost();
}

void AppInterface_onDrawFrame(AppHandle* appHandle) {
    appHandle->haxeRef->onDrawFrame();
}