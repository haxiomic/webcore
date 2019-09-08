/**
 * C-API for the component, this is needed for platforms that cannot interface with C++ without a C-API (like Swift)
 */

#ifndef MinimalGLC_h
#define MinimalGLC_h

#ifdef __cplusplus
extern "C" {
#endif

	void* minimalGLCreate();
	void minimalGLDestroy(void* ptr);

	void minimalGLFrame(void* ptr);

#ifdef __cplusplus
}
#endif

#endif /* MinimalGLC_h */
