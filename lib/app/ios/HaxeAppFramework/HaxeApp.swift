/**
    Swift wrapper for HaxeAppC.h
**/
public class HaxeApp {

    let ptr: UnsafeMutableRawPointer

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

    public func onGraphicsContextReady(_ context: EAGLContext) {
        let contextRef: UnsafeMutableRawPointer = Unmanaged.passUnretained(context).toOpaque()
        HaxeApp_onGraphicsContextReady(
            ptr,
            contextRef,
            // setGraphicsContext(ref)
            { ref in
                let context: EAGLContext = Unmanaged<EAGLContext>.fromOpaque(ref!).takeUnretainedValue()
                EAGLContext.setCurrent(context)
            }
        )
    }

    public func onGraphicsContextLost() {
        HaxeApp_onGraphicsContextLost(ptr)
    }

    public func onGraphicsContextResize(_ drawingBufferWidth: Int32, _ drawingBufferHeight: Int32, _ displayPixelRatio: Double) {
        HaxeApp_onGraphicsContextResize(ptr, drawingBufferWidth, drawingBufferHeight, displayPixelRatio)
    }

    public func onDrawFrame() {
        HaxeApp_onDrawFrame(ptr)
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
