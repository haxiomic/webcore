/**
 * C language wrapper for hxcpp-generated MainAppInterface class
 */

#ifndef CMainAppInterface_h
#define CMainAppInterface_h

typedef void MainAppInterfaceHandle;

#ifdef __cplusplus
extern "C" {
#endif

    const char* MainAppInterface_haxeInitializeAndRun();
    MainAppInterfaceHandle* MainAppInterface_createAppInstance();

    void MainAppInterface_onGraphicsContextReady(MainAppInterfaceHandle* app);
    void MainAppInterface_onGraphicsContextLost(MainAppInterfaceHandle* app);
    void MainAppInterface_onDrawFrame(MainAppInterfaceHandle* app);

#ifdef __cplusplus
}
#endif

#endif /* MinimalGLC_h */
