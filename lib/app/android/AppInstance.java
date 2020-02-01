package;

// Java wrapper for hxcpp generated library

public class AppInstance {

    static {
        System.loadLibrary("HaxeMainApp");
    }

    long ptr;

    public AppInstance() {
        ptr = JNIHaxeMainApp_createInstance();
    }

    public void onGraphicsContextReady() {
        JNIAppInterface_onGraphicsContextReady(ptr);
    }
    public void onGraphicsContextLost() {
        JNIAppInterface_onGraphicsContextLost(ptr);
    }
    public void onDrawFrame() {
        JNIAppInterface_onDrawFrame(ptr);
    }

    public void onDrawFrame() {
        JNIAppInterface_onDrawFrame(ptr);
    }

    public void destroy() {
        JNIHaxeMainApp_releaseInstance(ptr);
    }

    // JNI Methods
    static native String HaxeMainApp_haxeInitializeAndRun();
    static native long JNIHaxeMainApp_createInstance();
    static native void JNIHaxeMainApp_releaseInstance(long appHandle);

    static native void JNIAppInterface_onGraphicsContextReady(long appHandle);
    static native void JNIAppInterface_onGraphicsContextLost(long appHandle);
    static native void JNIAppInterface_onDrawFrame(long appHandle);

}
