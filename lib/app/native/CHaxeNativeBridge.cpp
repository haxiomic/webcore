/**
 * C interface for hxcpp henerated HaxeNativeBridge
 */

#include <stdio.h>
// hx/Native.h allows us to interface with the HXCPP generated code
#include <hxcpp.h>

#include <HaxeNativeBridge.h>
#include <app/AppInterface.h>

#include "CHaxeNativeBridge.h"

const char* HaxeNativeBridge_initializeAndRun() {
    return HaxeNativeBridge::initializeAndRun();
}

AppInterface* HaxeNativeBridge_createAppInstance() {
    return HaxeNativeBridge::createAppInstance();
}

void AppInterface_onNativeGraphicsContextReady(AppInterface* app) {

}

void AppInterface_onDrawFrame(AppInterface* app) {

}