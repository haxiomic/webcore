/**
 * C language wrapper for HaxeApp
 */

#ifndef HaxeAppC_h
#define HaxeAppC_h

#include <stdbool.h>

// callbacks
typedef void     (* MainThreadTick) ();
typedef void     (* SetGraphicsContext) (void* ref);
typedef int32_t  (* GetContextParamInt32) (void* ref);

#ifdef __cplusplus
extern "C" {
#endif

    // static methods
    const char* HaxeApp_haxeInitialize(MainThreadTick tickOnMainThread);
    void        HaxeApp_tick();
    void        HaxeApp_startEventLoopThread();
    void        HaxeApp_stopEventLoopThread();
    void        HaxeApp_runGc(bool major);
    bool        HaxeApp_isHaxeInitialized();
    bool        HaxeApp_isEventLoopThreadRunning();

    // instance methods
    void* HaxeApp_create();
    void  HaxeApp_release(void* appHandle);
    void  HaxeApp_onGraphicsContextReady(void* appHandle, void* contextRef, SetGraphicsContext setGraphicsContext, GetContextParamInt32 getDrawingBufferWidth, GetContextParamInt32 getDrawingBufferHeight);
    void  HaxeApp_onGraphicsContextLost(void* appHandle);
    void  HaxeApp_onDrawFrame(void* appHandle, int32_t drawingBufferWidth, int32_t drawingBufferHeight);

#ifdef __cplusplus
}
#endif

#endif /* MinimalGLC_h */
