/**
 * C language wrapper for hxcpp-generated AppInterface class
 */

#include <stdio.h>
// hx/Native.h allows us to interface with the HXCPP generated code
#include <hxcpp.h>

// include the hxcpp generated AppInterface class
#include <AppInterface.h>

#include "CAppInterface.h"

const char* AppInterface_haxeInitializeAndRun() {
    return AppInterface::haxeInitializeAndRun();
}

AppInterfaceHandle* AppInterface_createAppInstance() {
    return AppInterface::createAppInstance();
}

void AppInterface_onNativeGraphicsContextReady(AppInterfaceHandle* app) {
    // HX_JUST_GC_STACKFRAME
    // hx::ObjectPtr< ::gluon::es2::impl::ES2Context_obj > gl = ::gluon::es2::impl::ES2Context_obj::__alloc( HX_CTX );

    // ((hx::Native< app::AppInterface* >)app)-> onNativeGraphicsContextReady(gl);  
}

void AppInterface_onDrawFrame(AppInterfaceHandle* app) {

}