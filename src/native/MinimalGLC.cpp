/**
 * Implementation of C-API. It is here we directly comminicate with the generated hxcpp C++
 */

#include "MinimalGLC.h"

#include <stdio.h>

// hx/Native.h allows us to interface with the HXCPP generated code
#include <hx/Native.h>
#include <NativeApi.h>
#include <MinimalGLNativeInterface.h>

bool hxcppInitialized = false;

struct RefWrapper {
    hx::Ref<MinimalGLNativeInterface*> ref;
};

void* minimalGLCreate() {
    // initialize the hxcpp GC if it's not already initialized
    if (!hxcppInitialized) {
        const char *result = hx::Init();
        if (result != 0) {
            // failed to initialize
            fprintf(stderr, "Failed to initialize haxe: %s\n", result);
            return 0;
        }
        hxcppInitialized = true;
    }

    hx::NativeAttach autoAttach;
    hx::Native<MinimalGLNativeInterface*> component = NativeApi::create();

    RefWrapper* ptr = new RefWrapper();
    ptr->ref = component;

    return ptr;
}

void minimalGLDestroy(void* ptr) {
    ((RefWrapper*)ptr)->ref = 0;
    delete ((RefWrapper*)ptr);
}

void minimalGLDrawFrame(void* ptr) {
    ((RefWrapper*)ptr)->ref->drawFrame();
}