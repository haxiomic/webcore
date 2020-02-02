import GLKit

/**
 * View controller that hosts an instance of HaxeApp. Haxe's GC will be initialized when the view controller is created
 */
public class HaxeAppViewController: GLKViewController {
    
    public var haxeAppInstance: HaxeApp
    public var context: EAGLContext?
    
    var haxeGraphicsContextReady = false

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        HaxeApp.initialize()
        haxeAppInstance = HaxeApp()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        HaxeApp.initialize()
        haxeAppInstance = HaxeApp()
        super.init(coder: aDecoder)
    }
    
    deinit {
        releaseGraphicsContext()
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        initializeGraphicsContext()
    }
    
    private func initializeGraphicsContext() {
        // Create an OpenGL ES context and store it in our local variable.
        context = EAGLContext(api: .openGLES3)
        
        // Set the current EAGLContext to our context we created when performing OpenGL setup.
        EAGLContext.setCurrent(context)
        
        // Perform checks and unwrap options in order to perform more OpenGL setup.
        if let view = self.view as? GLKView, let context = context {
            // Set our view's context to the EAGLContext we just created.s
            view.context = context
        }
        
        self.preferredFramesPerSecond = 60;
    }
    
    
    /// Perform cleanup, and delete buffers and memory.
    private func releaseGraphicsContext() {
        // Set the current EAGLContext to our context. This ensures we are deleting buffers against it and potentially not a
        // different context.
        EAGLContext.setCurrent(context)

        // tell haxe that we've lost the graphics context
        haxeAppInstance.onGraphicsContextLost()
        
        // Set the current EAGLContext to nil.
        EAGLContext.setCurrent(nil)
        
        // Then nil out or variable that references our EAGLContext.
        context = nil
    }
    
    override public func glkView(_ view: GLKView, drawIn rect: CGRect) {
        // call onGraphicsContextReady() on first frame because at this point the view's drawable is fully initialized
        // we also rely on the screen framebuffer being bound during initialization of the GLContext
        if !haxeGraphicsContextReady {
            haxeAppInstance.onGraphicsContextReady()
            haxeGraphicsContextReady = true
        }
        
        // let frameTime_s = CACurrentMediaTime()
        
        haxeAppInstance.onDrawFrame()
    }

}
