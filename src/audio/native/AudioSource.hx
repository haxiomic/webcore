package audio.native;

import audio.native.MiniAudio.DecoderConfig;
import audio.native.MiniAudio.Mutex;
import audio.native.MiniAudio.Decoder;
import cpp.*;

@:allow(audio.native.AudioNode)
@:native('AudioSourceHx')
class AudioSource {

    final nativeSource: Star<ExternAudioSource>;
    final decoderConfig: DecoderConfig;

    function new(context: AudioContext) {
        cpp.vm.Gc.setFinalizer(this, Function.fromStaticFunction(finalizer));
        nativeSource = ExternAudioSource.create(context);
        
        var maDevice = context.maDevice;
        decoderConfig = MiniAudio.DecoderConfig.init(
            maDevice.playback.format,
            maDevice.playback.channels,
            maDevice.sampleRate
        );
    }

    static function finalizer(instance: AudioSource) {
        #if debug
        Stdio.printf("%s\n", "[debug] AudioSource.finalizer()");
        #end
        ExternAudioSource.destroy(instance.nativeSource);
    }

}

@:allow(audio.native.AudioContext)
class FileAudioSource extends AudioSource {

    function new(context: AudioContext, path: String) {
        super(context);
        nativeSource.maDecoder.initFile(path, Native.addressOf(decoderConfig));
    }

}

@:include('./native.h')
@:sourceFile('./native.c')
@:native('AudioSource') @:unreflective
@:structAccess
@:access(audio.native.AudioContext)
extern class ExternAudioSource {

    var maDecoder: Star<Decoder>;
    // var mutex: Mutex;

    @:native('~AudioSource')
    function free(): Void;

    @:native('new AudioSource')
    static function alloc(): Star<ExternAudioSource>;

    static inline function create(context: AudioContext): Star<ExternAudioSource> {
        var instance = alloc();
        instance.maDecoder = MiniAudio.Decoder.alloc();
        // @! mutex create
        return instance;
    }

    static inline function destroy(instance: ExternAudioSource): Void {
        instance.maDecoder.uninit();
        instance.maDecoder.free();
        instance.free();
    }

}