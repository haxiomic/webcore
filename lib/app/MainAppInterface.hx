package app;

import gluon.es2.GLContext;

/**
    Implement this interface to set the main app class
**/
@:nativeGen
@:keep
@:autoBuild(app.Macro.makeMainApp())
interface MainAppInterface {

    function onGraphicsContextReady(gl: GLContext): Void;
    function onGraphicsContextLost(): Void;
    function onDrawFrame(gl: GLContext): Void;

}

@:native('MainAppInterface')
@:nativeGen // cpp
@:expose // js
@:build(app.Macro.addNativeCode('./native/CMainAppInterface.h', './native/CMainAppInterface.cpp'))
@:keep
class MainAppInterfaceNative {

    static public function createAppInstance(): #if cpp cpp.Star<MainAppInterface> #else MainAppInterface #end {
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
@:allow(app.MainAppInterface)
@:allow(app.MainAppInterfaceNative)
class Static {

    static var createMainApp: () -> MainAppInterface;

}

/*
@:include('dispatch/dispatch.h')
extern class AppleDispatch {

    @:native('dispatch_get_main_queue')
    static function get_main_queue(): cpp.Star<cpp.Void>;

}
*/