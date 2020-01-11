import glfw.GLFW.*;
import gluon.es2.GLContext;
import gluon.es2.impl.ES2Context;
import haxe.MainLoop;
import cpp.Pointer;

class Main {

    static final startupFullscreen = false;

    static var window: Pointer<glfw.GLFW.GLFWwindow>;
    static var gl: GLContext;
    static var pixelRatio: Float = 1;
    static var mainLoopHandle: MainEvent;
    static var minimalGL: MinimalGL;

    /**
        @! Because this blocks while waiting for GLFW events, it synchronizes the haxe event loop with the framerate
        We should decouple these before deploying in a real-world product
    **/
    static function main() {
        glfwSetErrorCallback(onGLFWError);

        if (glfwInit() == 0) {
            throw "Could not initialize GLFW";
        }

        glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 2);
        glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
        glfwWindowHint(GLFW_SAMPLES, 0);
        glfwWindowHint(GLFW_REFRESH_RATE, 60); // use highest
        glfwWindowHint(GLFW_RESIZABLE, GLFW_TRUE);
        glfwWindowHint(GLFW_AUTO_ICONIFY, GLFW_TRUE);

        glfwWindowHint(GLFW_COCOA_RETINA_FRAMEBUFFER, GLFW_TRUE);
        glfwWindowHint(GLFW_SCALE_TO_MONITOR, GLFW_TRUE);

        var monitor = glfwGetPrimaryMonitor();
        var videoMode = glfwGetVideoMode(monitor);

        // examine video modes
        trace('VideoMode: ${videoMode.value.width}x${videoMode.value.height} @ ${videoMode.value.refreshRate}');
        trace(glfwGetVideoModes(monitor).map(m -> '${m.width}x${m.height} @ ${m.refreshRate}'));

        var windowWidth = Std.int(videoMode.value.width);
        var windowHeight = Std.int(videoMode.value.height);
        window = glfwCreateWindow(windowWidth, windowHeight, "MinimalGL", startupFullscreen ? glfwGetPrimaryMonitor() : null, null);

        if (window == null) {
            glfwTerminate();
            throw "Could not create GLFW window";
        }

        glfwMakeContextCurrent(window);

        // context settings
        glfwSwapInterval(1);

        // add event bindings
        glfwSetWindowSizeCallback(window, onResize);
        glfwSetCursorPosCallback(window, onMousePosChange);
        glfwSetMouseButtonCallback(window, onMouseButton);
        glfwSetKeyCallback(window, onKey);

        gl = new ES2Context();
        minimalGL = new MinimalGL(gl);

        var screenBufferSize = getScreenBufferSize();

        var windowSize = getWindowSize();
        var videoMode = glfwGetVideoMode(monitor);
        var videoModeSize = '${videoMode.value.width}x${videoMode.value.height}';

        #if macos
        pixelRatio = getPixelRatio();
        #end

        trace(videoModeSize, screenBufferSize, windowSize, pixelRatio);

        mainLoopHandle = MainLoop.add(mainLoop);
    }

    static function terminate() {
        glfwDestroyWindow(window);
        glfwTerminate();
        mainLoopHandle.stop();
    }

    static function mainLoop() {
        if (glfwWindowShouldClose(window) == 1) {
            terminate();
            return;
        }

        // pause all rendering the window is size 0,0
        var screenBufferSize = getScreenBufferSize();
        if (screenBufferSize.width > 0 && screenBufferSize.height > 0) {
            var t = haxe.Timer.stamp();

            minimalGL.drawFrame();

            // swap buffers blocks until the next frame sync
            // a better approach might be to handle rendering and windowing on a separate thread
            // the problem with blocking like this is it means we can't asynchronously schedule work that requires the GL context as this guy will prevent any work running until the next frame
            // we can resolve this by using non-blocking swapBuffers and OpenGL sync points and fences

            glfwSwapBuffers(window);
        }

        // give glfw a change to fire events for the next frame
        glfwPollEvents();
    }

    static function onGLFWError(code: Int, message: String) {
        trace('GLFW Error: $message ($code)');
    }

    static function onResize(window: cpp.Pointer<glfw.GLFW.GLFWwindow>, width: Int, height: Int) {
        var screenBufferSize = getScreenBufferSize();
        trace('Resizing window to ${screenBufferSize.width}x${screenBufferSize.height}');
    }

    static function onKey(key: Int, scanCode: Int, action: Int, mods: Int) {
    }

    static function onMousePosChange(x: Float, y: Float) {

    }

    static function onMouseButton(button: Int, action: Int, mods: Int) {
        
    }

    static inline function getWindowSize() {
        var width: Int = -1;
        var height: Int = -1;
        glfwGetWindowSize(window, Pointer.addressOf(width), Pointer.addressOf(height));
        return {
            width: width,
            height: height
        }
    }

    static inline function getScreenBufferSize() {
        var width: Int = -1;
        var height: Int = -1;
        glfwGetFramebufferSize(window, Pointer.addressOf(width), Pointer.addressOf(height));
        return {
            width: width,
            height: height
        }
    }

    static inline function getPixelRatio() {
        var xScale: cpp.Float32 = 0;
        var yScale: cpp.Float32 = 0;
        glfwGetWindowContentScale(window, Pointer.addressOf(xScale), Pointer.addressOf(yScale));
        return xScale;
    }

}