/**
    Swift wrapper for HaxeAppC.h
**/
public class HaxeApp {

    let ptr: UnsafeMutableRawPointer

    public init() {
        if !Thread.isMainThread {
            print("Haxe Error: called haxe method from a thread other than the main thread. This may cause instability because the event-loop runs on the main thread")
        }

        ptr = HaxeApp_create()
    }

    deinit {
        HaxeApp_release(ptr)
    }

    public func onGraphicsContextReady(_ context: EAGLContext) {
        let contextRef: UnsafeMutableRawPointer = Unmanaged.passUnretained(context).toOpaque()
        HaxeApp_onGraphicsContextReady(ptr, contextRef)
    }

    public func onGraphicsContextLost() {
        HaxeApp_onGraphicsContextLost(ptr)
    }

    public func onDrawFrame() {
        HaxeApp_onDrawFrame(ptr)
    }

    static public func initialize() {
        HaxeApp_initialize(
            // tickOnMainThread()
            {
                DispatchQueue.main.async(execute: { HaxeApp_tick() })
            },
            // setGraphicsContext(ref)
            { ref in
                let context: EAGLContext = Unmanaged<EAGLContext>.fromOpaque(ref!).takeUnretainedValue()
                EAGLContext.setCurrent(context)
            }
        )
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
