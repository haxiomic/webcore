package app;

class HaxeNativeBridge {

    static var createAppCallback: Null<() -> AppInterface> = null;

}

/**
    Generates a native-friendly C++ class "HaxeNativeBridge" at the root level
**/

@:nativeGen // cpp
@:expose // js
@:native('HaxeNativeBridge')
@:access(app.HaxeNativeBridge)
@:build(app.Macro.addNativeCode('./native/CHaxeNativeBridge.h', './native/CHaxeNativeBridge.cpp'))
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
        var result = untyped __cpp__('hx::Init()');
        return result;
    }

    static public function processEvents() @:privateAccess {
        return haxe.EntryPoint.processEvents();
    }
    #end

    static public function createAppInstance(): cpp.Star<AppInterface> {
        if (HaxeNativeBridge.createAppCallback != null) {
            return HaxeNativeBridge.createAppCallback();
        } else {
            throw 'App instance not defined; be sure to initialize hxcpp and implement the App class';
        }
    }

}

@:include('dispatch/dispatch.h')
extern class AppleDispatch {

    @:native('dispatch_get_main_queue')
    static function get_main_queue(): cpp.Star<cpp.Void>;

}