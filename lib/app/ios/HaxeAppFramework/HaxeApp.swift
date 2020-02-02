/**
    Swift wrapper for HaxeAppC.h
**/
public class HaxeApp {
    
    static public func initialize() {
        HaxeApp_initialize()
    }

    let ptr: UnsafeMutableRawPointer

    public init() {
        ptr = HaxeApp_create()
    }

    deinit {
        HaxeApp_release(ptr)
    }

    public func onGraphicsContextReady() {
        HaxeApp_onGraphicsContextReady(ptr)
    }

    public func onGraphicsContextLost() {
        HaxeApp_onGraphicsContextLost(ptr)
    }

    public func onDrawFrame() {
        HaxeApp_onDrawFrame(ptr)
    }

}
