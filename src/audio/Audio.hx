package audio;

import audio.MiniAudio.Result;
import cpp.*;

class Audio {
}

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
        return untyped __global__.AudioOut_addSource(this, source);
    }

    inline function removeSource(source: Star<AudioSource>): Bool {
        // @! source GC -1
        return untyped __global__.AudioOut_removeSource(this, source);
    }

    inline function sourceCount(): Int {
        return untyped __global__.AudioOut_sourceCount(this);
    }

    /**
     * @throws String if failed to create the output
     **/
    static inline function create(): Star<AudioOut> {
        var result: Result = ERROR;
        var audioOut = untyped  __global__.AudioOut_create(Native.addressOf(result));
        if (result != SUCCESS || audioOut == null) {
            throw 'Failed to create AudioOut ($result)';
        }
        return audioOut;
    }

    @:native('AudioOut_destroy')
    static function destroy(audioOut: Star<AudioOut>): Void;

}

@:include('./audio.h')
@:sourceFile('./audio.c')
@:native('AudioSource')
@:unreflective
@:structAccess
extern class AudioSource {

    /**
     * @throws String if failed to create the decoder
     **/
    static inline function createFileSource(path: ConstCharStar, outputFormat: MiniAudio.Format, channelCount: UInt32, sampleRate: UInt32): Star<AudioSource> {
        var result: Result = ERROR;
        var audioSource = untyped  __global__.AudioSource_createFileSource(path, outputFormat, channelCount, sampleRate, Native.addressOf(result));
        if (result != SUCCESS || audioSource == null) {
            throw 'Failed to create AudioSource ($result)';
        }
        return audioSource;
    }

    @:native('AudioSource_destroy')
    static function destroy(audioSource: Star<AudioSource>): Void;

}