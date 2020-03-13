import GLKit

/**
    Swift wrapper for HaxeAppC.h
**/
public class HaxeApp {

    let ptr: UnsafeMutableRawPointer
    let touchEventHandler: TouchEventHandler
    // we keep a reference to the glkView to prevent it from being collected
    var glkView: GLKView?
    
    // track known state so we know if haxe needs a state update
    var frameWidth: Double?
    var frameHeight: Double?
    var isActive: Bool?

    /// Calling this automatically initializes haxe if it's not already initialized
    public init() {
        if !Thread.isMainThread {
            print("Haxe Error: called haxe method from a thread other than the main thread. This may cause instability because the event-loop runs on the main thread")
        }

        if !HaxeApp.isHaxeInitialized() {
            HaxeApp.haxeInitialize()
        }

        ptr = HaxeApp_create()

        touchEventHandler = TouchEventHandler(ptr)
    }

    deinit {
        HaxeApp_release(ptr)
    }
    
    /// Only calls haxe onResize if dimensions have changed (so it is fine to call multiple times with the same values)
    public func onResize(_ width: Double, _ height: Double) {
        if width != frameWidth || height != frameHeight {
            HaxeApp_onResize(ptr, width, height)
            frameWidth = width
            frameHeight = height
        }
    }
    
    /// Only calls haxe onActivate once when state changes (so it is fine to call multiple times withouth a state change)
    public func onActivate() {
        if isActive != true {
            HaxeApp_onActivate(ptr)
            isActive = true
        }
    }
    
    /// Only calls haxe onDeactivate once when state changes (so it is fine to call multiple times withouth a state change)
    public func onDeactivate() {
        if isActive != false {
            HaxeApp_onDeactivate(ptr)
            isActive = false
        }
    }

    /// Call this when the graphics context is fully initialized and the **context draw buffer is the currently bound framebuffer**
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

    public func touchesBegan(_ touches: Set<UITouch>, in view: UIView) {
        touchEventHandler.touchesBegan(touches, in: view)
    }

    public func touchesMoved(_ touches: Set<UITouch>, in view: UIView) {
        touchEventHandler.touchesMoved(touches, in: view)
    }

    public func touchesEnded(_ touches: Set<UITouch>, in view: UIView) {
        touchEventHandler.touchesEnded(touches, in: view)
    }

    public func touchesCancelled(_ touches: Set<UITouch>, in view: UIView) {
        touchEventHandler.touchesCancelled(touches, in: view)
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

class TouchEventHandler {

    let ptr: UnsafeMutableRawPointer
    
    var touchTypeActiveCount = Dictionary<String, Int>()
    var touchTypePrimaryId = Dictionary<String, Int32>()
    
    var touchIdMap: Dictionary<UITouch, Int32> = [:]
    var touchIdCounter: Int32 = 0

    public init(_ ptr: UnsafeMutableRawPointer) {
        self.ptr = ptr
    }

    // PointerEvent input
    public func touchesBegan(_ touches: Set<UITouch>, in view: UIView) {
        for touch in touches {
            let pointerType = getTouchPointerType(touch)
            let initialActiveCount = getActiveCountForPointerType(pointerType)

            addTouch(touch)

            let buttonStates = getTouchButtonStates(touch)
            let pos = touch.location(in: view)
            let tilt = getTouchTilt(touch, in: view)
            let pointerId = getTouchPointerId(touch)
        
            if initialActiveCount == 0 {
                touchTypePrimaryId[pointerType] = pointerId
            }

            HaxeApp_onPointerDown(
                ptr,
                pointerId, // pointerId
                pointerType, // pointerType
                isTouchPrimary(touch), // isPrimary
                buttonStates.0, // button
                buttonStates.1, // buttons
                Double(pos.x), // x
                Double(pos.y), // y
                Double(touch.majorRadius * 2), // width
                Double(touch.majorRadius * 2), // height
                getTouchPressure(touch), // pressure
                0, // tangentialPressure
                tilt.0, // tiltX
                tilt.1, // tiltY
                0 // twist
            );
        }
    }

    public func touchesMoved(_ touches: Set<UITouch>, in view: UIView) {
        for touch in touches {
            let buttonStates = getTouchButtonStates(touch)
            let pos = touch.location(in: view)
            let tilt = getTouchTilt(touch, in: view)

            HaxeApp_onPointerMove(
                ptr,
                getTouchPointerId(touch), // pointerId
                getTouchPointerType(touch), // pointerType
                isTouchPrimary(touch), // isPrimary
                buttonStates.0, // button
                buttonStates.1, // buttons
                Double(pos.x), // x
                Double(pos.y), // y
                Double(touch.majorRadius * 2), // width
                Double(touch.majorRadius * 2), // height
                getTouchPressure(touch), // pressure
                0, // tangentialPressure
                tilt.0, // tiltX
                tilt.1, // tiltY
                0 // twist
            );
        }
    }

    public func touchesEnded(_ touches: Set<UITouch>, in view: UIView) {
        for touch in touches {
            let buttonStates = getTouchButtonStates(touch)
            let pos = touch.location(in: view)
            let tilt = getTouchTilt(touch, in: view)

            HaxeApp_onPointerUp(
                ptr,
                getTouchPointerId(touch), // pointerId
                getTouchPointerType(touch), // pointerType
                isTouchPrimary(touch), // isPrimary
                buttonStates.0, // button
                buttonStates.1, // buttons
                Double(pos.x), // x
                Double(pos.y), // y
                Double(touch.majorRadius * 2), // width
                Double(touch.majorRadius * 2), // height
                getTouchPressure(touch), // pressure
                0, // tangentialPressure
                tilt.0, // tiltX
                tilt.1, // tiltY
                0 // twist
            );

            removeTouch(touch)
        }
    }

    public func touchesCancelled(_ touches: Set<UITouch>, in view: UIView) {
        for touch in touches {
            let buttonStates = getTouchButtonStates(touch)
            let pos = touch.location(in: view)
            let tilt = getTouchTilt(touch, in: view)

            HaxeApp_onPointerCancel(
                ptr,
                getTouchPointerId(touch), // pointerId
                getTouchPointerType(touch), // pointerType
                isTouchPrimary(touch), // isPrimary
                buttonStates.0, // button
                buttonStates.1, // buttons
                Double(pos.x), // x
                Double(pos.y), // y
                Double(touch.majorRadius * 2), // width
                Double(touch.majorRadius * 2), // height
                getTouchPressure(touch), // pressure
                0, // tangentialPressure
                tilt.0, // tiltX
                tilt.1, // tiltY
                0 // twist
            );

            removeTouch(touch)
        }
    }

    func getTouchPressure(_ touch: UITouch) -> Double {
        if touch.maximumPossibleForce > 0 {
            return Double(touch.force / touch.maximumPossibleForce)
        } else {
            return 0.5
        }
    }

    func getTouchPointerType(_ touch: UITouch) -> String {
        switch touch.type {
        case .direct, .indirect: return "touch"
        case .pencil: return "pen"
        @unknown default:
            fatalError()
        }
    }

    func getTouchButtonStates(_ touch: UITouch) -> (Int32, Int32) {
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

    func getTouchTilt(_ touch: UITouch, in view: UIView) -> (Double, Double) {
        // convert altitude-azimuth to tilt xy
        let azimuthAngle = touch.azimuthAngle(in: view)
        let tanAlt = tan(touch.altitudeAngle);
        let radToDeg = 180.0 / Double.pi;
        return (
            tiltX: Double(atan(cos(azimuthAngle) / tanAlt)) * radToDeg,
            tiltY: Double(atan(sin(azimuthAngle) / tanAlt)) * radToDeg
        )
    }

    func getTouchPointerId(_ touch: UITouch) -> Int32 {
        return touchIdMap[touch]!
    }

    func isTouchPrimary(_ touch: UITouch) -> Bool {
        let pointerType = getTouchPointerType(touch)
        return getTouchPointerId(touch) == touchTypePrimaryId[pointerType]
    }
    
    func getActiveCountForPointerType(_ pointerType: String) -> Int {
        return touchTypeActiveCount[pointerType] ?? 0
    }
    
    func addTouch(_ touch: UITouch) {
        let id: Int32 = touchIdCounter
        touchIdCounter = touchIdCounter + 1

        // we use negative IDs for touch and pointers to distingush from traditional pointers
        touchIdMap[touch] = -id - 1
        
        let pointerType = getTouchPointerType(touch)
        let activeCount = getActiveCountForPointerType(pointerType)
        touchTypeActiveCount[pointerType] = activeCount + 1
    }

    func removeTouch(_ touch: UITouch) {
        if touchIdMap.removeValue(forKey: touch) == nil {
            return
        }
        
        let pointerType = getTouchPointerType(touch)
        let activeCount = touchTypeActiveCount[pointerType]!
        touchTypeActiveCount[pointerType] = activeCount - 1

        // reset touch counter if we have no touches
        if touchIdMap.count == 0 {
            touchIdCounter = 0
        }
    }

}
