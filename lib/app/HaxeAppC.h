/**
 * C language wrapper for HaxeApp
 */

#ifndef HaxeAppC_h
#define HaxeAppC_h

#include <stdbool.h>

// callbacks
typedef void (* MainThreadTick) ();
typedef void (* SelectGraphicsContext) (void* ref);

#ifdef __cplusplus
extern "C" {
#endif

    // static methods
    const char* HaxeApp_initialize(MainThreadTick tickOnMainThread, SelectGraphicsContext selectGraphicsContext);
    void        HaxeApp_tick();
    void        HaxeApp_startEventLoopThread();
    void        HaxeApp_stopEventLoopThread();
    void        HaxeApp_runGc(bool major);

    // instance methods
    void* HaxeApp_create();
    void  HaxeApp_release(void* appHandle);
    void  HaxeApp_onGraphicsContextReady(void* appHandle, void* contextRef);
    void  HaxeApp_onGraphicsContextLost(void* appHandle);
    void  HaxeApp_onGraphicsContextResize(void* appHandle, int drawingBufferWidth, int drawingBufferHeight, double displayPixelRatio);
    void  HaxeApp_onDrawFrame(void* appHandle);

#ifdef __cplusplus
}
#endif

#endif /* MinimalGLC_h */
