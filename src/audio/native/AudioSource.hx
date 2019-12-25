package audio.native;

import audio.native.MiniAudio.Result;
import cpp.*;

@:include('./audio.h')
@:sourceFile('./audio.c')
@:native('AudioSource')
@:unreflective
@:structAccess
extern class AudioSource {

    /**
     * @throws String if failed to create the decoder
     **/
    static inline function createFileSource(path: ConstCharStar, channelCount: UInt32, sampleRate: UInt32): Star<AudioSource> {
        var result: Result = ERROR;
        var audioSource = untyped  __global__.AudioSource_createFileSource(path, channelCount, sampleRate, Native.addressOf(result));
        if (result != SUCCESS || audioSource == null) {
            throw 'Failed to create AudioSource ($result)';
        }
        return audioSource;
    }

    @:native('AudioSource_destroy')
    static function destroy(audioSource: Star<AudioSource>): Void;

}