/**
 * C language wrapper for hxcpp-generated AppInterface class
 */

#ifndef HaxeMainAppC_h
#define HaxeMainAppC_h

typedef void AppInterfaceHandle;

#ifdef __cplusplus
extern "C" {
#endif

    const char*         HaxeMainApp_haxeInitializeAndRun();
    AppInterfaceHandle* HaxeMainApp_createInstance();
    void                HaxeMainApp_releaseInstance(AppInterfaceHandle* appHandle);

    void AppInterface_onGraphicsContextReady(AppInterfaceHandle* appHandle);
    void AppInterface_onGraphicsContextLost(AppInterfaceHandle* appHandle);
    void AppInterface_onDrawFrame(AppInterfaceHandle* appHandle);

#ifdef __cplusplus
}
#endif

#endif /* MinimalGLC_h */
