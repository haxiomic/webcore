/**
 * C language wrapper for hxcpp-generated AppInterface class
 */

#ifndef CHaxeMainApp_h
#define CHaxeMainApp_h

typedef void AppInterfaceHandle;

#ifdef __cplusplus
extern "C" {
#endif

    const char*         HaxeMainApp_haxeInitializeAndRun();
    AppInterfaceHandle* HaxeMainApp_createInstance();

    void AppInterface_onGraphicsContextReady(AppInterfaceHandle* app);
    void AppInterface_onGraphicsContextLost(AppInterfaceHandle* app);
    void AppInterface_onDrawFrame(AppInterfaceHandle* app);

#ifdef __cplusplus
}
#endif

#endif /* MinimalGLC_h */
