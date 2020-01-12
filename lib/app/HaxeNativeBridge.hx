package app;

import gluon.es2.GLContext;


class HaxeNativeBridge {

    static var createAppCallback: Null<() -> App> = null;

    public static function setCreateAppCallback(cb: () -> App) {
        createAppCallback = cb;
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
class HaxeNativeBridgeImpl {

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

    static public function createAppInstance(): App {
        if (HaxeNativeBridge.createAppCallback != null) {
            return HaxeNativeBridge.createAppCallback();
        } else {
            throw 'App instance not defined; be sure to initialize hxcpp and implement the App class';
        }
    }

}