/**
 * C language wrapper for hxcpp-generated MainAppInterface class
 */

#include <stdio.h>
// hx/Native.h allows us to interface with the HXCPP generated code
#include <hxcpp.h>

// include the hxcpp generated MainAppInterface class
#include <MainAppInterface.h>

#include "CMainAppInterface.h"

const char* MainAppInterface_haxeInitializeAndRun() {
    return MainAppInterface::haxeInitializeAndRun();
}

MainAppInterfaceHandle* MainAppInterface_createAppInstance() {
    return MainAppInterface::createAppInstance();
}

void MainAppInterface_onGraphicsContextReady(MainAppInterfaceHandle* app) {
    // HX_JUST_GC_STACKFRAME
    // hx::ObjectPtr< ::gluon::es2::impl::ES2Context_obj > gl = ::gluon::es2::impl::ES2Context_obj::__alloc( HX_CTX );

    // ((hx::Native< app::MainAppInterface* >)app)-> onNativeGraphicsContextReady(gl);  
}

void MainAppInterface_onGraphicsContextLost(MainAppInterfaceHandle* app) {
}

void MainAppInterface_onDrawFrame(MainAppInterfaceHandle* app) {

}