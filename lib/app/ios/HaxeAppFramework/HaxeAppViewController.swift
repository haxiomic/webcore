import GLKit

/**
 * View controller that hosts an instance of HaxeApp
 */
public class HaxeAppViewController: GLKViewController {
    
    public var haxeAppInstance: HaxeApp
    public var context: EAGLContext?
    
    var haxeGraphicsContextReady = false

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        haxeAppInstance = HaxeApp()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
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

    override public func viewDidLayoutSubviews() {
        haxeAppInstance.onResize(Double(view.frame.width), Double(view.frame.height))
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
        super.touchesBegan(touches, with: event)
        
        for touch in touches {
            let buttonStates = getButtonStates(touch)
            let pos = touch.location(in: view)
            let tilt = getTilt(touch)
            
            haxeAppInstance.onPointerDown(
                pointerId: getTouchId(touch),
                pointerType: getPointerType(touch),
                isPrimary: isPrimary(touch),
                button: buttonStates.0,
                buttons: buttonStates.1,
                x: Double(pos.x),
                y: Double(pos.y),
                width: Double(touch.majorRadius * 2),
                height: Double(touch.majorRadius * 2),
                pressure: getPressure(touch),
                tangentialPressure: 0,
                tiltX: tilt.0,
                tiltY: tilt.1,
                twist: 0
            );
        }
    }

    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        for touch in touches {
            let buttonStates = getButtonStates(touch)
            let pos = touch.location(in: view)
            let tilt = getTilt(touch)
            
            haxeAppInstance.onPointerMove(
                pointerId: getTouchId(touch),
                pointerType: getPointerType(touch),
                isPrimary: isPrimary(touch),
                button: buttonStates.0,
                buttons: buttonStates.1,
                x: Double(pos.x),
                y: Double(pos.y),
                width: Double(touch.majorRadius * 2),
                height: Double(touch.majorRadius * 2),
                pressure: getPressure(touch),
                tangentialPressure: 0,
                tiltX: tilt.0,
                tiltY: tilt.1,
                twist: 0
            );
        }
    }

    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        for touch in touches {
            let buttonStates = getButtonStates(touch)
            let pos = touch.location(in: view)
            let tilt = getTilt(touch)
            
            haxeAppInstance.onPointerUp(
                pointerId: getTouchId(touch),
                pointerType: getPointerType(touch),
                isPrimary: isPrimary(touch),
                button: buttonStates.0,
                buttons: buttonStates.1,
                x: Double(pos.x),
                y: Double(pos.y),
                width: Double(touch.majorRadius * 2),
                height: Double(touch.majorRadius * 2),
                pressure: getPressure(touch),
                tangentialPressure: 0,
                tiltX: tilt.0,
                tiltY: tilt.1,
                twist: 0
            );
            removeTouch(touch)
        }
    }

    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        for touch in touches {
            let buttonStates = getButtonStates(touch)
            let pos = touch.location(in: view)
            let tilt = getTilt(touch)
            
            haxeAppInstance.onPointerCancel(
                pointerId: getTouchId(touch),
                pointerType: getPointerType(touch),
                isPrimary: isPrimary(touch),
                button: buttonStates.0,
                buttons: buttonStates.1,
                x: Double(pos.x),
                y: Double(pos.y),
                width: Double(touch.majorRadius * 2),
                height: Double(touch.majorRadius * 2),
                pressure: getPressure(touch),
                tangentialPressure: 0,
                tiltX: tilt.0,
                tiltY: tilt.1,
                twist: 0
            );
            removeTouch(touch)
        }
    }

    private var touchIdMap: Dictionary<UITouch, Int32> = [:]
    private var touchIdCounter: Int32 = 0

    func getPressure(_ touch: UITouch) -> Double {
        if touch.maximumPossibleForce > 0 {
            return Double(touch.force / touch.maximumPossibleForce)
        } else {
            return 0.5
        }
    }
    
    func getPointerType(_ touch: UITouch) -> String {
        switch touch.type {
        case .direct, .indirect: return "touch"
        case .pencil: return "pen"
        @unknown default:
            fatalError()
        }
    }
    
    func getButtonStates(_ touch: UITouch) -> (Int32, Int32) {
        switch touch.phase {
        case .began:
            return (button: 0, buttons: 1)
        case .moved, .stationary:
            return (button: -1, buttons: 1)
        case .ended, .cancelled:
            return (button: 0, buttons: 0)
        @unknown default:
            fatalError()
        }
    }
    
    func getTilt(_ touch: UITouch) -> (Double, Double) {
        // convert altitude-azimuth to tilt xy
        let azimuthAngle = touch.azimuthAngle(in: view)
        let tanAlt = tan(touch.altitudeAngle);
        let radToDeg = 180.0 / Double.pi;
        return (
            tiltX: Double(atan(cos(azimuthAngle) / tanAlt)) * radToDeg,
            tiltY: Double(atan(sin(azimuthAngle) / tanAlt)) * radToDeg
        )
    }

    func getTouchId(_ touch: UITouch) -> Int32 {
        if let id = touchIdMap[touch] {
            return id
        } else {
            let id: Int32 = touchIdCounter
            touchIdCounter = touchIdCounter + 1
            touchIdMap[touch] = id
            return id
        }
    }

    func isPrimary(_ touch: UITouch) -> Bool {
        // this relies on the touchIdCounter being reset to 0 when all touches have been removed
        // see removeTouch
        return getTouchId(touch) == 0
    }
    
    func removeTouch(_ touch: UITouch) {
        touchIdMap.removeValue(forKey: touch)
        // reset touch counter if we have no touches
        if touchIdMap.count == 0 {
            touchIdCounter = 0
        }
    }

}
