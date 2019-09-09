/**
 * Java cannot call C methods directly like Swift, instead we need to create a Java Native Interface wrapper
 */

#include <jni.h>
#include <MinimalGLC.h>

#define JAVA_METHOD(returnType, name) JNIEXPORT returnType JNICALL Java_haxiomic_minimalglapp_MinimalGL_##name

extern "C" {
    JAVA_METHOD(jlong, create) (JNIEnv * env, jobject obj,  jint width, jint height);
    JAVA_METHOD(void, frame) (JNIEnv * env, jobject obj, jlong ptr);
    JAVA_METHOD(void, destroy) (JNIEnv * env, jobject obj, jlong ptr);
};

// return the instance pointer as a jlong
JAVA_METHOD(jlong, create) (JNIEnv * env, jobject obj,  jint width, jint height) {
    return (jlong) minimalGLCreate();
}

JAVA_METHOD(void, frame) (JNIEnv * env, jobject obj, jlong ptr) {
    minimalGLFrame((void*) ptr);
}

JAVA_METHOD(void, destroy) (JNIEnv * env, jobject obj, jlong ptr) {
    minimalGLDestroy((void*) ptr);
}
