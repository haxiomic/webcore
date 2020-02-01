package app;

@:native('HaxeApp')
@:nativeGen // cpp
@:expose // js
@:keep
#if !display
@:build(app.Macro.hxcppAddNativeCode('./HaxeAppC.h', './HaxeAppC.cpp'))

#if (iphoneos || iphonesim)
@:build(app.Macro.copyToOutput('./ios/HaxeAppFramework'))
@:build(app.Macro.copyToOutput('./ios/HaxeAppFramework.xcodeproj'))
#end

#end
class HaxeApp {

    static public function create(): HaxeAppInterface {
        return Static.createMainApp();
    }

    /**
        Initialize hxcpp, call `main()` and block until event queue is empty (or return if no `main()` is defined)

        Only initializes once, subsequent calls do nothing if already successfully initialized

        - Initializes the hxcpp GC (`hx:SetTopOfStack`)
        - Initializes defined classes (`__boot__.cpp`)
        - If defined, calls the user's main() (see `__hxcpp_lib_main` in `__lib__.cpp`)
        - If user's main() is defined, `EntryPoint.run()` will be called, this is the event loop and will **block** until all events are processed

        `hx::Init()` is defined in hxcpp/src/StdLibs.cpp
    **/
    #if cpp
    @:noDebug static public function initialize(): cpp.ConstCharStar {
        if (Static.initialized) {
            return null;
        } else {
            var result: cpp.ConstCharStar = untyped __cpp__('hx::Init()'); // requires hx/native.h, defined in hxcpp/src/StdLibs.cpp
            if (result == null) {
                Static.initialized = true;
            }
            return result;
        }
    }
    #end

}

/**
    We have to use a separate class to store data because `@:nativeGen` doesn't properly handle all references;
    If the `@:nativeGen` class is added to __boot__.cpp to initialize fields, it will be incorrectly referenced
**/
@:allow(app.HaxeApp)
class Static {

    static var initialized = false;
    
    #if cpp
    static var createMainApp: cpp.Callable<() -> HaxeAppInterface>;
    #else
    static var createMainApp: () -> HaxeAppInterface;
    #end


}


/*
@:include('dispatch/dispatch.h')
extern class AppleDispatch {

    @:native('dispatch_get_main_queue')
    static function get_main_queue(): cpp.Star<cpp.Void>;

}
*/