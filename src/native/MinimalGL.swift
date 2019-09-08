import UIKit
import GLKit

/**
 * Swift wrapper over MinimalGL C-API
 */
public class MinimalGL {
    
    let ptr: UnsafeMutableRawPointer
    private let view: GLKView
    
    public init(view: GLKView) {
        self.view = view
        ptr = minimalGLCreate()
    }
    
    deinit {
        minimalGLDestroy(ptr)
    }

    public func frame() {
        minimalGLFrame(self.ptr)
    }
    
}
