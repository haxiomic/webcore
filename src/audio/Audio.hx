package audio;

import audio.MiniAudio.Result;
import cpp.*;

class Audio {


}

@:include('./audio.h')
@:sourceFile('./audio.c')
@:native('AudioDevice')
@:unreflective
@:structAccess
extern class AudioDevice {

    var maDevice: Star<MiniAudio.Device>;
    // var volume (get, set): Float32;

    inline function start(): Result {
        return maDevice.start();
    }

    inline function stop(): Result {
        return maDevice.stop();
    }

    inline function addSource(source: Star<AudioSource>): Result {
        return untyped __global__.AudioDevice_addSource(this, source);
    }

    inline function removeSource(source: Star<AudioSource>): Void {
        untyped __global__.AudioDevice_removeSource(this, source);
    }

    inline function sourceCount(): Int {
        return untyped __global__.AudioDevice_sourceCount(this);
    }

    /*
    inline function get_volume(): Float32 {
        return untyped __global__.AudioDevice_getVolume(this);
    }

    inline function set_volume(v: Float32): Float32 {
        untyped __global__.AudioDevice_setVolume(this, v);
        return v;
    }
    */

    @:native('AudioDevice_create')
    static function create(result: Star<MiniAudio.Result>): Star<AudioDevice>;

    @:native('AudioDevice_destroy')
    static function destroy(device: Star<AudioDevice>): Void;

}

@:include('./audio.h')
@:sourceFile('./audio.c')
@:native('AudioSource')
@:unreflective
@:structAccess
extern class AudioSource {

}

/**
 *
 */
class FileSource {

    public function new(path: String) {

    }

}