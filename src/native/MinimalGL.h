/**
 * C-API for the component
 */

#ifndef MinimalGL_h
#define MinimalGL_h

#ifdef __cplusplus
extern "C" {
#endif

	void* minimalGLCreate(int width, int height);
	void minimalGLDestroy(void* ptr);
	void minimalGLFrame(void* ptr);

#ifdef __cplusplus
}
#endif

#endif /* MinimalGL_h */
