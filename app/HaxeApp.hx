package app;

#if js
@:native('HaxeApp')
#end
@:nativeGen // cpp
@:keep
#if !display

@:build(app.Macro.hxcppAddNativeCode('./HaxeAppC.h', './HaxeAppC.cpp'))

#if (iphoneos || iphonesim)
@:build(app.Macro.generateHaxeCompileScript())
@:build(app.Macro.copyHaxeAppFramework())
#end

#end
class HaxeApp {

	#if cpp

	/**
		Create an instance of a class that implements `HaxeAppInterface`.
		If `classPath` is `null`, an instance of the first class that implements `HaxeAppInterface` will be returned
	**/
	@:analyzer(no_optimize)
	static public function create(classPath: cpp.ConstCharStar): HaxeAppInterface {
		try {
			if (classPath != null) {
				var constructor: cpp.Callable<() -> HaxeAppInterface> = Internal.constructors.get(classPath);
				if (constructor == null) {
					var possibleClassPaths = [for (key in Internal.constructors.keys()) key];
					throw 'Haxe class path "$classPath" was not registered. Implement HaxeAppInterface to register a class. Registered classes: $possibleClassPaths';
				}
				return constructor();
			}
			if (Internal.defaultConstructor != null) {
				return Internal.defaultConstructor();
			}
		} catch(e: Any) {
			Sys.println('Haxe Exception: ${Std.string(e)}');
			throw e;
		}
		return null;
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
	@:noDebug static public function haxeInitialize(tickOnMainThread: MainThreadTick): cpp.ConstCharStar {
		if (Internal.initialized) {
			return null;
		} else {
			var result: cpp.ConstCharStar = untyped __cpp__('hx::Init()'); // requires hx/native.h, defined in hxcpp/src/StdLibs.cpp
			if (result == null) {
				Internal.initialized = true;
				Internal.nativeTickOnMainThread = tickOnMainThread;
				Internal.startEventLoopThread();
			}
			return result;
		}
	}

	@:noDebug static public function isHaxeInitialized() {
		return Internal.initialized;
	}

	@:noDebug static public function isEventLoopThreadRunning() {
		return Internal.eventLoopRunning;
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
		Call this when external code executes haxe code that might schedule events
	**/
	static public function wakeEventLoop() {
		haxe.EntryPoint.wakeup();
	}

	/**
		Checks if new events were scheduled between calls to this method.
		This is a work-around because MainLoop doesn't trigger wakeup when adding events.
		In the future we can replace it by redefining MainLoop to wakeup the event loop when events are added
	**/
	static public function eventLoopNeedsWake() @:privateAccess {
		var needsWake = haxe.MainLoop.pending != Internal._eventsScheduledBeforeLatestEvent;
		Internal._eventsScheduledBeforeLatestEvent = haxe.MainLoop.pending;
		return needsWake;
	}
	#end

	static public inline function getBundleIdentifier() {
		return Internal.bundleIdentifier;
	}

	static public inline function setBundleIdentifier(v: String) {
		return Internal.bundleIdentifier = v;
	}

}

#if cpp
typedef MainThreadTick = cpp.Callable<() -> Void>;
#end

/**
	We have to use a separate class to store data because `@:nativeGen` doesn't properly handle all references;
	If the `@:nativeGen` class is added to __boot__.cpp to initialize fields, it will be incorrectly referenced
**/
@:allow(app.HaxeApp)
@:unreflective
class Internal {

	static public var bundleIdentifier = 'haxeapp.Framework';
	
	#if cpp
	// these are intentionally _not_ assigned initial values
	// this is because if this classes __init__ method is called after registerConstructor, we lose their values
	static var constructors: Map<String, cpp.Callable<() -> HaxeAppInterface>>;
	static var defaultConstructor: Null<cpp.Callable<() -> HaxeAppInterface>>;
	static function registerConstructor(classPath: String, constructor: cpp.Callable<() -> HaxeAppInterface>) {
		if (defaultConstructor == null) {
			defaultConstructor = constructor;
		}
		if (constructors == null) {
			constructors = new Map();
		}
		constructors.set(classPath, constructor);
	}

	// native platform callbacks
	static var nativeTickOnMainThread: MainThreadTick;

	static var initialized = false;
	static var eventLoopRunning = false;
	static var eventLoopExitLock = new sys.thread.Lock();
	static var tickLock = new sys.thread.Lock();

	static var _nextTick_s: Float = -1.0; // accessed by haxe main thread and event-loop thread; synchronize before read/write

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
		_nextTick_s = @:privateAccess haxe.EntryPoint.processEvents();
		tickLock.release();
	}
	#end

}