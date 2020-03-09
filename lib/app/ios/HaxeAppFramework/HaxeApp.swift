import GLKit

/**
    Swift wrapper for HaxeAppC.h
**/
public class HaxeApp {

    let ptr: UnsafeMutableRawPointer
    // we keep a reference to the glkView to prevent it from being collected
    var glkView: GLKView?

    public init() {
        if !Thread.isMainThread {
            print("Haxe Error: called haxe method from a thread other than the main thread. This may cause instability because the event-loop runs on the main thread")
        }

        if !HaxeApp.isHaxeInitialized() {
            HaxeApp.haxeInitialize()
        }

        ptr = HaxeApp_create()
    }

    deinit {
        HaxeApp_release(ptr)
    }

    public func onResize(_ width: Double, _ height: Double) {
        HaxeApp_onResize(ptr, width, height)
    }

    public func onGraphicsContextReady(_ view: GLKView) {
        self.glkView = view

        let viewRef: UnsafeMutableRawPointer = Unmanaged.passUnretained(view).toOpaque()
        HaxeApp_onGraphicsContextReady(
            ptr,
            viewRef,

            // context attributes
            //  alpha
            view.drawableColorFormat != GLKViewDrawableColorFormat.RGB565,
            //  depth
            view.drawableDepthFormat != GLKViewDrawableDepthFormat.formatNone,
            //  stencil
            view.drawableStencilFormat != GLKViewDrawableStencilFormat.formatNone,
            //  antialias
            view.drawableMultisample != GLKViewDrawableMultisample.multisampleNone,
            
            // setGraphicsContext(ref)
            { ref in
                let view: GLKView = Unmanaged<GLKView>.fromOpaque(ref!).takeUnretainedValue()
                EAGLContext.setCurrent(view.context)
            },
            // getDrawingBufferWidth
            { ref in
                let view: GLKView = Unmanaged<GLKView>.fromOpaque(ref!).takeUnretainedValue()
                return Int32(view.drawableWidth)
            },
            // getDrawingBufferHeight
            { ref in
                let view: GLKView = Unmanaged<GLKView>.fromOpaque(ref!).takeUnretainedValue()
                return Int32(view.drawableHeight)
            }
        )
    }

    public func onGraphicsContextLost() {
        self.glkView = nil
        HaxeApp_onGraphicsContextLost(ptr)
    }

    public func onDrawFrame(_ drawingBufferWidth: Int32, _ drawingBufferHeight: Int32) {
        HaxeApp_onDrawFrame(ptr, drawingBufferWidth, drawingBufferHeight)
    }

    public func onPointerDown(pointerId: Int32, pointerType: String, isPrimary: Bool, button: Int32, buttons: Int32, x: Double, y: Double, width: Double, height: Double, pressure: Double, tangentialPressure: Double, tiltX: Double, tiltY: Double, twist: Double) {
        HaxeApp_onPointerDown(ptr, pointerId, pointerType, isPrimary, button, buttons, x, y, width, height, pressure, tangentialPressure, tiltX, tiltY, twist);
    }

    public func onPointerMove(pointerId: Int32, pointerType: String, isPrimary: Bool, button: Int32, buttons: Int32, x: Double, y: Double, width: Double, height: Double, pressure: Double, tangentialPressure: Double, tiltX: Double, tiltY: Double, twist: Double) {
        HaxeApp_onPointerMove(ptr, pointerId, pointerType, isPrimary, button, buttons, x, y, width, height, pressure, tangentialPressure, tiltX, tiltY, twist);
    }

    public func onPointerUp(pointerId: Int32, pointerType: String, isPrimary: Bool, button: Int32, buttons: Int32, x: Double, y: Double, width: Double, height: Double, pressure: Double, tangentialPressure: Double, tiltX: Double, tiltY: Double, twist: Double) {
        HaxeApp_onPointerUp(ptr, pointerId, pointerType, isPrimary, button, buttons, x, y, width, height, pressure, tangentialPressure, tiltX, tiltY, twist);
    }
    
    public func onPointerCancel(pointerId: Int32, pointerType: String, isPrimary: Bool, button: Int32, buttons: Int32, x: Double, y: Double, width: Double, height: Double, pressure: Double, tangentialPressure: Double, tiltX: Double, tiltY: Double, twist: Double) {
        HaxeApp_onPointerCancel(ptr, pointerId, pointerType, isPrimary, button, buttons, x, y, width, height, pressure, tangentialPressure, tiltX, tiltY, twist);
    }

    static public func haxeInitialize() {
        HaxeApp_haxeInitialize(
            // tickOnMainThread()
            {
                DispatchQueue.main.async(execute: { HaxeApp_tick() })
            }
        )
    }

    static public func isHaxeInitialized() -> Bool {
        return HaxeApp_isHaxeInitialized();
    }

    static public func isEventLoopThreadRunning() -> Bool {
        return HaxeApp_isEventLoopThreadRunning();
    }

    static public func startEventLoopThread() {
        HaxeApp_startEventLoopThread();
    }

    static public func stopEventLoopThread() {
        HaxeApp_stopEventLoopThread();
    }

    static public func runGc(major: Bool) {
        HaxeApp_runGc(major);
    }

}
