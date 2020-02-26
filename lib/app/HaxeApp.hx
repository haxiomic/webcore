package app;

@:native('HaxeApp')
@:nativeGen // cpp
@:expose // js
@:keep
#if !display

@:build(app.Macro.hxcppAddNativeCode('./HaxeAppC.h', './HaxeAppC.cpp'))

#if (iphoneos || iphonesim)
@:build(app.Macro.generateHaxeCompileScript())
@:build(app.Macro.copyHaxeAppFramework())
#end

#end
class HaxeApp {

    static public function create(): HaxeAppInterface {
        #if cpp
        return new HaxeAppInterfaceWrapper(Static.createMainApp);
        #else
        return Static.createMainApp();
        #end
    }

    /**
        Initialize hxcpp, call `main()` and block until event queue is empty (or return if no `main()` is defined)

        Only initializes once, subsequent calls do nothing if already successfully initialized

        - Initializes the hxcpp GC (`hx:SetTopOfStack`)
        - Initializes defined classes (`__boot__.cpp`)
        - If defined, calls the user's main() (see `__hxcpp_lib_main` in `__lib__.cpp`)
        - If user's main() is defined, `EntryPoint.run()` will be called, this is the event loop and will **block** until all events are processed

        `hx::Init()` is defined in hxcpp/src/StdLibs.cpp

        Documentation on using hxcpp's GC
        - https://github.com/HaxeFoundation/hxcpp/blob/master/docs/ThreadsAndStacks.md
        - https://groups.google.com/forum/#!topic/haxelang/V-jzaEX7YD8
    **/
    #if cpp
    @:noDebug static public function initialize(): cpp.ConstCharStar {
        if (Static.initialized) {
            return null;
        } else {
            var result: cpp.ConstCharStar = untyped __cpp__('hx::Init()'); // requires hx/native.h, defined in hxcpp/src/StdLibs.cpp
            if (result == null) {
                HaxeMainThread.start();
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

/**
    The haxe event loop is run in a separate haxe-created thread
    When exposing a HaxeAppInstance to an external native context, we must therefore synchronize with the main haxe thread when making calls
**/
#if cpp
@:notMainApp
private class HaxeAppInterfaceWrapper implements HaxeAppInterface {

    final appInterface: HaxeAppInterface;

    public function new(createAppInterface: cpp.Callable<() -> HaxeAppInterface>) {
        var appInterface: Null<HaxeAppInterface> = null;
        HaxeMainThread.runWithMainThreadMutex(() -> appInterface = createAppInterface());
        this.appInterface = appInterface;
    }

    public function onGraphicsContextReady(context: webgl.GLContext) {
        HaxeMainThread.runWithMainThreadMutex(() -> appInterface.onGraphicsContextReady(context));
    }

    public function onGraphicsContextLost() {
        HaxeMainThread.runWithMainThreadMutex(() -> appInterface.onGraphicsContextLost());
    }

    public function onDrawFrame() {
        HaxeMainThread.runWithMainThreadMutex(() -> appInterface.onDrawFrame());
    }

}

private class HaxeMainThread {

    static public var running(default, null): Bool = false;
    static final haxeExecutionMutex = new sys.thread.Mutex();
    static final eventLoopComplete = new sys.thread.Lock();

    /**
        Start the event loop thread (considered the haxe main thread)
    **/
    static public function start() {
        if (running) {
            throw 'Event-loop thread has already been started';
        }
        // start main haxe thread (to handle the haxe event loop)
        running = true;
        sys.thread.Thread.create(eventLoop);
    }

    /**
        Stop the event loop thread (synchronously) 
    **/
    static public function stop() @:privateAccess {
        runWithMainThreadMutex(() -> running = false);
        haxe.EntryPoint.wakeup();
        eventLoopComplete.wait();
    }

    /**
        Execute code in the current local thread but in synchronization with the main thread
        Main-thread code cannot run during this callback and this callback will wait for main-thread code to complete before executing
    **/
    static public inline function runWithMainThreadMutex(callback: () -> Void) {
        haxeExecutionMutex.acquire();
        callback();
        haxeExecutionMutex.release();
        haxe.EntryPoint.wakeup();
    }

    /**
        Run code in the haxe main thread
    **/
    static public inline function runInMainThread(callback: () -> Void) {
        haxe.EntryPoint.runInMainThread(callback);
    }

    static function eventLoop() @:privateAccess {
        // event loop
        while (true) {
            haxeExecutionMutex.acquire();

            if (!running) {
                break;
            }

            var nextTick_s = haxe.EntryPoint.processEvents();
            
            haxeExecutionMutex.release();

            // we keep the event-loop alive even if there are no events (nextTick_s < 0)
            // this differs from the default haxe event loop because haxe code can be executed externally and so new events may be scheduled
            if (nextTick_s < 0) {
                haxe.EntryPoint.sleepLock.wait();
            } else if (nextTick_s > 0) {
                haxe.EntryPoint.sleepLock.wait(nextTick_s); // wait until nextTick or wakeup() call
            }
        }

        eventLoopComplete.release();
    }

}
#end