public class AppInterface {

    let ptr: UnsafeMutableRawPointer

    public init() {
        ptr = HaxeMainApp_createInstance()
    }

    deinit {
        HaxeMainApp_releaseInstance(ptr)
    }

    public func onGraphicsContextReady() {
        AppInterface_onGraphicsContextReady(ptr)
    }

    public func onGraphicsContextLost() {
        AppInterface_onGraphicsContextLost(ptr)
    }

    public func onDrawFrame() {
        AppInterface_onDrawFrame(ptr)
    }

}