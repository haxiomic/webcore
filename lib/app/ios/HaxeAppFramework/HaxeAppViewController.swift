import GLKit

/**
 * View controller that hosts an instance of HaxeApp
 */
public class HaxeAppViewController: GLKViewController {
    
    public let haxeAppInstance: HaxeApp
    public var context: EAGLContext?
    
    var haxeGraphicsContextReady = false
    var haxeFrameWidth: CGFloat = -1
    var haxeFrameHeight: CGFloat = -1

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        haxeAppInstance = HaxeApp()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        postInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        haxeAppInstance = HaxeApp()
        super.init(coder: aDecoder)
        postInit()
    }
    
    deinit {
        releaseGraphicsContext()
    }
    
    func postInit() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.onApplicationDidBecomeActive(notification:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onApplicationDidEnterBackground(notification:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onApplicationWillEnterForeground(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onApplicationWillResignActive(notification:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onApplicationWillTerminate(notification:)), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    @objc func onApplicationDidBecomeActive(notification: Notification) {
        print("-- onDidBecomeActive --")
    }
    @objc func onApplicationDidEnterBackground(notification: Notification) {
        print("-- onDidEnterBackground --")
    }
    @objc func onApplicationWillEnterForeground(notification: Notification) {
        print("-- onWillEnterForeground --")
    }
    @objc func onApplicationWillResignActive(notification: Notification) {
        print("-- onWillResignActive --")
    }
    @objc func onApplicationWillTerminate(notification: Notification) {
        print("-- onWillTerminate --")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        initializeGraphicsContext()
    }

    override public func viewDidLayoutSubviews() {
        if view.frame.width != haxeFrameWidth || view.frame.height != haxeFrameHeight {
            haxeAppInstance.onResize(Double(view.frame.width), Double(view.frame.height))
            haxeFrameWidth = view.frame.width
            haxeFrameHeight = view.frame.height
        }
    }
    
    private func initializeGraphicsContext() {
        // Create an OpenGL ES context and store it in our local variable.
        context = EAGLContext(api: .openGLES3)
        
        // Set the current EAGLContext to our context we created when performing OpenGL setup.
        EAGLContext.setCurrent(context)
        
        // Perform checks and unwrap options in order to perform more OpenGL setup.
        if let view = self.view as? GLKView, let context = context {
            // Set our view's context to the EAGLContext we just created
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
            haxeAppInstance.onGraphicsContextReady(view)
            haxeGraphicsContextReady = true
        }
        
        haxeAppInstance.onDrawFrame(Int32(view.drawableWidth), Int32(view.drawableHeight))
    }

    // PointerEvent input
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        haxeAppInstance.touchesBegan(touches, in: view)
        super.touchesBegan(touches, with: event)
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        haxeAppInstance.touchesMoved(touches, in: view)
        super.touchesMoved(touches, with: event)
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        haxeAppInstance.touchesEnded(touches, in: view)
        super.touchesEnded(touches, with: event)
    }

    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        haxeAppInstance.touchesCancelled(touches, in: view)
        super.touchesCancelled(touches, with: event)
    }

}
