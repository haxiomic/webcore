/**
 * C interface for hxcpp henerated HaxeNativeBridge
 */

#ifndef CHaxeNativeBridge_h
#define CHaxeNativeBridge_h

typedef void AppInterface;

#ifdef __cplusplus
extern "C" {
#endif

    const char* HaxeNativeBridge_initializeAndRun();
    AppInterface* HaxeNativeBridge_createAppInstance();

    void AppInterface_onNativeGraphicsContextReady(AppInterface* app);
    void AppInterface_onDrawFrame(AppInterface* app);

#ifdef __cplusplus
}
#endif

#endif /* MinimalGLC_h */
