package audio.native;

import audio.native.MiniAudio.Result;
import cpp.*;

@:include('./audio.h')
@:sourceFile('./audio.c')
@:native('AudioOut')
@:unreflective
@:structAccess
extern class AudioOut {

    var maDevice: Star<MiniAudio.Device>;
    // var volume (get, set): Float32;

    inline function start(): Result {
        // @! GC +1
        return maDevice.start();
    }

    inline function stop(): Result {
        // @! GC -1
        return maDevice.stop();
    }

    inline function addSource(source: Star<AudioSource>): Result {
        // @! source GC +1
        if (source == null) return INVALID_ARGS;
        return untyped __global__.AudioOut_addSource(this, source);
    }

    inline function removeSource(source: Star<AudioSource>): Bool {
        // @! source GC -1
        if (source == null) return false;
        return untyped __global__.AudioOut_removeSource(this, source);
    }

    inline function sourceCount(): Int {
        return untyped __global__.AudioOut_sourceCount(this);
    }

    /**
     * @throws String if failed to create the output
     **/
    static inline function create(?sampleRate: UInt32 = 0): Star<AudioOut> {
        var result: Result = ERROR;
        var audioOut = untyped  __global__.AudioOut_create(sampleRate, Native.addressOf(result));
        if (result != SUCCESS || audioOut == null) {
            throw 'Failed to create AudioOut ($result)';
        }
        return audioOut;
    }

    @:native('AudioOut_destroy')
    static function destroy(audioOut: Star<AudioOut>): Void;

}