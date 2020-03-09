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
    void  HaxeApp_release(void* ptr);
    void  HaxeApp_onResize(void* ptr, double width, double height);
    void  HaxeApp_onGraphicsContextReady(
        void* ptr,
        void* contextRef,
        bool alpha,
        bool depth,
        bool stencil,
        bool antialias,
        SetGraphicsContext setGraphicsContext,
        GetContextParamInt32 getDrawingBufferWidth,
        GetContextParamInt32 getDrawingBufferHeight
    );
    void  HaxeApp_onGraphicsContextLost(void* ptr);
    void  HaxeApp_onDrawFrame(void* ptr, int32_t drawingBufferWidth, int32_t drawingBufferHeight);

    /**
     * # PointerEvent API
     * 
     * All pointer functions have the following arguments
     * - void* ptr
     * - int32_t pointerId
     * - const char* pointerType – "mouse", "touch", "pen"
     * - bool isPrimary
     * - int32_t button
     * - int32_t buttons
     * - double x
     * - double y
     * - double width
     * - double height
     * - double pressure
     * - double tangentialPressure
     * - double tiltX
     * - double tiltY
     * - double twist
     */
    void  HaxeApp_onPointerDown(void* ptr, int32_t pointerId, const char* pointerType, bool isPrimary, int32_t button, int32_t buttons, double x, double y, double width, double height, double pressure, double tangentialPressure, double tiltX, double tiltY, double twist);
    void  HaxeApp_onPointerMove(void* ptr, int32_t pointerId, const char* pointerType, bool isPrimary, int32_t button, int32_t buttons, double x, double y, double width, double height, double pressure, double tangentialPressure, double tiltX, double tiltY, double twist);
    void  HaxeApp_onPointerUp(void* ptr, int32_t pointerId, const char* pointerType, bool isPrimary, int32_t button, int32_t buttons, double x, double y, double width, double height, double pressure, double tangentialPressure, double tiltX, double tiltY, double twist);
    void  HaxeApp_onPointerCancel(void* ptr, int32_t pointerId, const char* pointerType, bool isPrimary, int32_t button, int32_t buttons, double x, double y, double width, double height, double pressure, double tangentialPressure, double tiltX, double tiltY, double twist);

#ifdef __cplusplus
}
#endif

#endif /* MinimalGLC_h */
