/**
 * C language wrapper for hxcpp-generated HaxeAppInterface class
 */

#ifndef HaxeAppC_h
#define HaxeAppC_h

typedef void HaxeAppHandle;

#ifdef __cplusplus
extern "C" {
#endif

    // static methods
    const char* HaxeApp_initialize();

    // instance methods
    HaxeAppHandle* HaxeApp_create();
    void           HaxeApp_release(HaxeAppHandle* appHandle);
    void HaxeApp_onGraphicsContextReady(HaxeAppHandle* appHandle);
    void HaxeApp_onGraphicsContextLost(HaxeAppHandle* appHandle);
    void HaxeApp_onDrawFrame(HaxeAppHandle* appHandle);

#ifdef __cplusplus
}
#endif

#endif /* MinimalGLC_h */
