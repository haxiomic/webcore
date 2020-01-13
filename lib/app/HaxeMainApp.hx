package app;

@:native('HaxeMainApp')
@:nativeGen // cpp
@:expose // js
#if !display
@:build(app.Macro.addNativeCode('./native/CHaxeMainApp.h', './native/CHaxeMainApp.cpp'))
#end
@:keep
class HaxeMainApp {

    static public function createInstance(): #if cpp cpp.Star<AppInterface> #else AppInterface #end {
        return Static.createMainApp();
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
    @:noDebug static public function haxeInitializeAndRun(): cpp.ConstCharStar {
        var result = untyped __cpp__('hx::Init()'); // requires hx/native.h
        return result;
    }
    #end

}

/**
    We have to use a separate class to store data because `@:nativeGen` doesn't properly handle all references
    If the `@:nativeGen` class is added to __boot__.cpp to initialize fields, it will be incorrectly referenced
**/
@:allow(app.AppInterface)
@:allow(app.HaxeMainApp)
class Static {

    static var createMainApp: () -> AppInterface;

}


/*
@:include('dispatch/dispatch.h')
extern class AppleDispatch {

    @:native('dispatch_get_main_queue')
    static function get_main_queue(): cpp.Star<cpp.Void>;

}
*/