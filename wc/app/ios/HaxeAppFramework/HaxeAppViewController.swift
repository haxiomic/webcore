import GLKit

/**
 * View controller that hosts an instance of HaxeApp
 */
public class HaxeAppViewController: GLKViewController {
    
    /// set the desired haxe class path from interface builder
    @IBInspectable var haxeClassPath: String?
    
    public var haxeAppInstance: HaxeApp!
    public var context: EAGLContext?
    
    var haxeGraphicsContextReady = false
    var isVisible: Bool?
    
    public init(glkView: GLKView? = nil, haxeClassPath: String? = nil) {
        super.init(nibName: nil, bundle: nil)
        
        if let glkView = glkView {
            self.view = glkView
        } else {
            let defaultGLKView = GLKView()
            defaultGLKView.isMultipleTouchEnabled = true
            defaultGLKView.drawableMultisample = .multisample4X
            defaultGLKView.drawableColorFormat = .RGBA8888
            defaultGLKView.drawableDepthFormat = .format24
            defaultGLKView.drawableStencilFormat = .format8
            self.view = defaultGLKView
        }

        self.haxeClassPath = haxeClassPath
        initializeView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        releaseGraphicsContext()
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        initializeView()
    }
    
    /// Should be called when interface builder fields have been set (awakeFromNib)
    func initializeView() {
        haxeAppInstance = HaxeApp(classPath: haxeClassPath ?? nil)

        // catch application events
        NotificationCenter.default.addObserver(self, selector: #selector(self.onApplicationDidBecomeActive(notification:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onApplicationWillEnterForeground(notification:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onApplicationWillResignActive(notification:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onApplicationWillTerminate(notification:)), name: UIApplication.willTerminateNotification, object: nil)
        
        initializeGraphicsContext()
    }

    override public func viewDidLayoutSubviews() {
        haxeAppInstance.onResize(Double(view.frame.width), Double(view.frame.height))
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        haxeAppInstance.onActivate()
        isVisible = true
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        haxeAppInstance.onDeactivate()
        isVisible = false
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
        haxeAppInstance?.onGraphicsContextLost()
        
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
    
    // handle application events
    // we only trigger haxe activate/deactivate event if the view is visible
    // this is because view visiblity changes already trigger activate deactivate events
    @objc func onApplicationDidBecomeActive(notification: Notification) {
        if isVisible == true {
            haxeAppInstance.onActivate()
        }
    }
    @objc func onApplicationWillEnterForeground(notification: Notification) {
        if isVisible == true {
            haxeAppInstance.onActivate()
        }
    }
    @objc func onApplicationWillResignActive(notification: Notification) {
        if isVisible == true {
            haxeAppInstance.onDeactivate()
        }
    }
    @objc func onApplicationWillTerminate(notification: Notification) {
        if isVisible == true {
            haxeAppInstance.onDeactivate()
        }
    }

}
