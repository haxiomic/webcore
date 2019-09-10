package haxiomic.minimalglapp;

// Java wrapper for hxcpp generated library

public class MinimalGL {

    static {
        System.loadLibrary("MinimalGLJNIWrapper");
    }

    long ptr;

    public MinimalGL(int width, int height) {
        ptr = create(width, height);
    }

    public void drawFrame() {
        drawFrame(ptr);
    }

    public void destroy() {
        destroy(ptr);
    }

    // these static methods are implemented in C++
    static native long create(int width, int height);
    static native void drawFrame(long ptr);
    static native void destroy(long ptr);

}
