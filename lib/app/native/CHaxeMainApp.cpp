/**
 * C language wrapper for hxcpp-generated AppInterface class
 */

#include <stdio.h>
// hx/Native.h allows us to interface with the HXCPP generated code
#include <hxcpp.h>

// include the hxcpp generated AppInterface class
#include <HaxeMainApp.h>

#include "CHaxeMainApp.h"

const char* HaxeMainApp_haxeInitializeAndRun() {
    return HaxeMainApp::haxeInitializeAndRun();
}

AppInterfaceHandle* HaxeMainApp_createInstance() {
    return HaxeMainApp::createInstance();
}

void AppInterface_onGraphicsContextReady(AppInterfaceHandle* app) {
    // HX_JUST_GC_STACKFRAME
    // hx::ObjectPtr< ::gluon::es2::impl::ES2Context_obj > gl = ::gluon::es2::impl::ES2Context_obj::__alloc( HX_CTX );

    // ((hx::Native< app::AppInterface* >)app)-> onNativeGraphicsContextReady(gl);  
}

void AppInterface_onGraphicsContextLost(AppInterfaceHandle* app) {
}

void AppInterface_onDrawFrame(AppInterfaceHandle* app) {

}