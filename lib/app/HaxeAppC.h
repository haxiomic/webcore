/**
 * C language wrapper for hxcpp-generated HaxeAppInterface class
 */

#ifndef HaxeAppC_h
#define HaxeAppC_h

#ifdef __cplusplus
extern "C" {
#endif

    // static methods
    const char* HaxeApp_initialize();

    // instance methods
    void* HaxeApp_create();
    void  HaxeApp_release(void* appHandle);
    void  HaxeApp_onGraphicsContextReady(void* appHandle);
    void  HaxeApp_onGraphicsContextLost(void* appHandle);
    void  HaxeApp_onDrawFrame(void* appHandle);

#ifdef __cplusplus
}
#endif

#endif /* MinimalGLC_h */
