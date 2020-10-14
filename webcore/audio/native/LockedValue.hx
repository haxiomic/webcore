package webcore.audio.native;

import cpp.*;

/**
	Guards a value behind an mutex lock
	If the value is not primitive (and therefore not copied on return) you should keep read/write to the `acquire()` callback rather than using `get()` and `set()`
**/
@:access(webcore.audio.AudioContext)
@:generic class LockedValue<T> {

	public final mutex: Star<MiniAudio.Mutex>;

	var value: T;
	
	public function new(context: AudioContext) {
		this.mutex = MiniAudio.Mutex.alloc();
		this.mutex.init(context.maDevice.pContext);
		cpp.vm.Gc.setFinalizer(this, Function.fromStaticFunction(LockedValueFinalizer.finalizer));
	}

	@:noDebug public inline function get(): T {
		return mutex.locked(() -> value);
	}

	@:noDebug public inline function set(v: T): T {
		return mutex.locked(() -> value = v);
	}

	@:noDebug public inline function acquire(cb: T -> Void): Void {
		mutex.lock();
		cb(value);
		mutex.unlock();
	}

	@:noDebug public inline function getUnsafe(): T {
		return value;
	}

	@:noDebug public inline function setUnsafe(v: T): T {
		return value = v;
	}

}

@:access(webcore.audio.native.LockedValue)
private class LockedValueFinalizer {
	static public function finalizer<T>(instance: LockedValue<T>) {
		#if debug
		Stdio.printf("%s\n", "[debug] LockedValue.finalizer()");
		#end
		instance.mutex.uninit();
		instance.mutex.free();
	}
}