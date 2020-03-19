package;

// Java wrapper for hxcpp generated library

public class AppInstance {

    static {
        System.loadLibrary("HaxeApp");
    }

    long ptr;

    public AppInstance() {
        ptr = JNIHaxeApp_createInstance();
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
        JNIHaxeApp_releaseInstance(ptr);
    }

    // JNI Methods
    static native String HaxeApp_haxeInitializeAndRun();
    static native long JNIHaxeApp_createInstance();
    static native void JNIHaxeApp_releaseInstance(long appHandle);

    static native void JNIAppInterface_onGraphicsContextReady(long appHandle);
    static native void JNIAppInterface_onGraphicsContextLost(long appHandle);
    static native void JNIAppInterface_onDrawFrame(long appHandle);

}
