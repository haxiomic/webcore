package app;

import gluon.es2.GLContext;

typedef EventHandler = {
    @:optional function onNativeGraphicsContextReady(gl: GLContext): Void;
    @:optional function onDrawFrame(): Void;
}

class HaxeNativeBridge {

    static var eventHandlers = new Array<EventHandler>();

    static public function addEventHandler(handler: EventHandler) {
        eventHandlers.push(handler);
    }

    static public function removeEventHandler(handler: EventHandler) {
        return eventHandlers.remove(handler);
    }

}

/**
    Generates a native-friendly C++ class "HaxeNativeBridge" at the root level
**/

#if cpp 
@:build(app.Macro.generateC())
#end
@:nativeGen // cpp
@:expose // js
@:native('HaxeNativeBridge')
@:access(app.HaxeNativeBridge)
@:keep
class HaxeNativeBridgeImpl {

    // Events

    static public function onNativeGraphicsContextReady(gl: GLContext) {
        for (handler in HaxeNativeBridge.eventHandlers) {
            if (handler.onNativeGraphicsContextReady != null) handler.onNativeGraphicsContextReady(gl);
        }
    }

    static public function onDrawFrame() {
        for (handler in HaxeNativeBridge.eventHandlers) {
            if (handler.onDrawFrame != null) handler.onDrawFrame();
        }
    }

    /**
        Initialize hxcpp, call `main()` and block until event queue is empty (or return if no `main()` is defined)

        - Initializes the hxcpp GC (`hx:SetTopOfStack`)
        - Initializes defined classes (`__boot__.cpp`)
        - If defined, calls the user's main() (see `__hxcpp_lib_main` in `__lib__.cpp`)
        - If user's main() is defined, `EntryPoint.run()` will be called, this is the event loop and will **block** until all events are processed

        `hx::Init()` is defined in hxcpp/src/StdLibs.cpp
    **/
    #if cpp
    @:noDebug static public function initializeAndRun(): cpp.ConstCharStar {
        return untyped __cpp__('hx::Init()');
    }

    static public function processEvents() @:privateAccess {
        return haxe.EntryPoint.processEvents();
    }
    #end

}