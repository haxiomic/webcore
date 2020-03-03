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
        return Internal.createMainApp();
    }

    /**
        Initialize hxcpp, call `main()` and block until event queue is empty (or return if no `main()` is defined)

        Only initializes once, subsequent calls do nothing if already successfully initialized

        - Initializes the hxcpp GC (`hx:SetTopOfStack`)
        - Initializes defined classes (`__boot__.cpp`)
        - If defined, calls the user's main() (see `__hxcpp_lib_main` in `__lib__.cpp`)
        - If user's main() is defined, `EntryPoint.run()` will be called, this is the event loop and will **block** until all events are processed
        - Starts the event loop thread

        `hx::Init()` is defined in hxcpp/src/StdLibs.cpp

        Documentation on using hxcpp's GC
        - https://github.com/HaxeFoundation/hxcpp/blob/master/docs/ThreadsAndStacks.md
        - https://groups.google.com/forum/#!topic/haxelang/V-jzaEX7YD8
    **/
    #if cpp
    @:noDebug static public function initialize(tickOnMainThread: MainThreadTick, selectGraphicsContext: SelectGraphicsContext): cpp.ConstCharStar {
        if (Internal.initialized) {
            return null;
        } else {
            var result: cpp.ConstCharStar = untyped __cpp__('hx::Init()'); // requires hx/native.h, defined in hxcpp/src/StdLibs.cpp
            if (result == null) {
                Internal.initialized = true;
                Internal.nativeTickOnMainThread = tickOnMainThread;
                Internal.nativeSelectGraphicsContext = selectGraphicsContext;
                Internal.startEventLoopThread();
            }
            return result;
        }
    }

    /**
        Execute queued and due events. Should only be called from the main haxe thread
    **/
    static public function tick() {
        Internal.tick();
    }

    /**
        Starts the event loop thread (should only be called after `stopEventLoopThread`). Automatically called by `initialize`
    **/
    static public function startEventLoopThread() {
        Internal.startEventLoopThread();
    }

    /**
        Stops the haxe event loop thread. Scheduled events and calls to `runInMainThread` will no longer be executed
    **/
    static public function stopEventLoopThread() {
        Internal.stopEventLoopThread();
    }

    /**
        Run the garbage collector to perform a major collection
    **/
    static public function runGc(major: Bool) {
        cpp.vm.Gc.run(major);
    }

    /**
        This is required because the graphics context might be used within events which can be executed at anytime and therefore we need to ensure the correct graphics context is activated
    **/
    static public function setGlobalGraphicsContext(ref: cpp.Star<cpp.Void>) {
        Internal.graphicsContext = ref;
    }

    /**
        Call this when external code executes haxe code that might schedule events
    **/
    static public function wakeEventLoop() {
        haxe.EntryPoint.wakeup();
    }

    /**
        Checks if new events were scheduled between calls to this method
        This is a work-around because MainLoop doesn't trigger wakeup when adding events
        In the future we should probably redefine MainLoop rather than use this method
    **/
    static public function eventLoopNeedsWake() @:privateAccess {
        var needsWake = haxe.MainLoop.pending != Internal._eventsScheduledBeforeLatestEvent;
        Internal._eventsScheduledBeforeLatestEvent = haxe.MainLoop.pending;
        return needsWake;
    }
    #end

}

#if cpp
typedef SelectGraphicsContext = cpp.Callable<(ref: cpp.Star<cpp.Void>) -> Void>;
typedef MainThreadTick = cpp.Callable<() -> Void>;
#end

/**
    We have to use a separate class to store data because `@:nativeGen` doesn't properly handle all references;
    If the `@:nativeGen` class is added to __boot__.cpp to initialize fields, it will be incorrectly referenced
**/
@:allow(app.HaxeApp)
@:unreflective
class Internal {

    static var initialized = false;
    
    #if cpp
    static var createMainApp: cpp.Callable<() -> HaxeAppInterface>;
    #else
    static var createMainApp: () -> HaxeAppInterface;
    #end


    #if cpp
    static var graphicsContext: cpp.Star<cpp.Void> = null;
    static var eventLoopRunning = false;
    static var eventLoopExitLock = new sys.thread.Lock();
    // native platform callbacks
    static var nativeTickOnMainThread: MainThreadTick;
    static var nativeSelectGraphicsContext: SelectGraphicsContext;
    static var tickLock = new sys.thread.Lock();
    static var _nextTick_s: Float = -1.0;

    static var _eventsScheduledBeforeLatestEvent: Null<haxe.MainLoop.MainEvent> = null;

    static function startEventLoopThread() {
        if (eventLoopRunning) {
            throw 'Failed to start event loop thread; already running';
        }

        eventLoopRunning = true;
        sys.thread.Thread.create(() -> @:privateAccess {
            while (eventLoopRunning) {
                // trace('before tick', _nextTick_s);
                // queue tick() on the main thread and wait until executed
                nativeTickOnMainThread();
                tickLock.wait();
                // trace('after tick', _nextTick_s);

                // we keep the event-loop alive even if there are no events (nextTick_s < 0)
                // this differs from the default haxe event loop because haxe code can be executed externally and so new events may be scheduled
                if (_nextTick_s < 0) {
                    haxe.EntryPoint.sleepLock.wait();
                } else if (_nextTick_s > 0) {
                    haxe.EntryPoint.sleepLock.wait(_nextTick_s); // wait until nextTick or wakeup() call
                }
            }

            eventLoopExitLock.release();
        });
    }

    /**
        Stop the event loop thread (block until complete)
    **/
    static function stopEventLoopThread() {
        if (eventLoopRunning) {
            eventLoopRunning = false;
            haxe.EntryPoint.wakeup();
            eventLoopExitLock.wait();
        }
    }

    /**
        Should only be called from the main haxe thread
    **/
    static inline function tick() {
        if (graphicsContext != null) {
            nativeSelectGraphicsContext(graphicsContext);
        }
        _nextTick_s = @:privateAccess haxe.EntryPoint.processEvents();
        tickLock.release();
    }
    #end

}