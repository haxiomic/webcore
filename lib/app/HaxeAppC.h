/**
 * C language wrapper for HaxeApp
 */

#ifndef HaxeAppC_h
#define HaxeAppC_h

typedef void (* SelectGraphicsContext) (void* ref);
typedef void (* MainThreadTick) ();

#ifdef __cplusplus
extern "C" {
#endif

    // static methods
    const char* HaxeApp_initialize(MainThreadTick tickOnMainThread, SelectGraphicsContext selectGraphicsContext);
    void        HaxeApp_tick();

    // instance methods
    void* HaxeApp_create();
    void  HaxeApp_release(void* appHandle);
    void  HaxeApp_onGraphicsContextReady(void* appHandle, void* contextRef);
    void  HaxeApp_onGraphicsContextLost(void* appHandle);
    void  HaxeApp_onDrawFrame(void* appHandle);

#ifdef __cplusplus
}
#endif

#endif /* MinimalGLC_h */
