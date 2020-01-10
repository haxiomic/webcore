package audio.native;

import cpp.*;

@:access(audio.AudioContext)
@:generic class LockedValue<T> {

    final mutex: Star<MiniAudio.Mutex>;

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

}

@:access(audio.native.LockedValue)
private class LockedValueFinalizer {
    static public function finalizer<T>(instance: LockedValue<T>) {
        #if debug
        Stdio.printf("%s\n", "[debug] LockedValue.finalizer()");
        #end
        instance.mutex.uninit();
        instance.mutex.free();
    }
}