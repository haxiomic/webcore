/**
 * C language wrapper for hxcpp-generated AppInterface class
 */

#ifndef CAppInterface_h
#define CAppInterface_h

typedef void AppInterfaceHandle;

#ifdef __cplusplus
extern "C" {
#endif

    const char* AppInterface_haxeInitializeAndRun();
    AppInterfaceHandle* AppInterface_createAppInstance();

    void AppInterface_onNativeGraphicsContextReady(AppInterfaceHandle* app);
    void AppInterface_onDrawFrame(AppInterfaceHandle* app);

#ifdef __cplusplus
}
#endif

#endif /* MinimalGLC_h */
