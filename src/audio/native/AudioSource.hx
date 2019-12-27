package audio.native;

import typedarray.ArrayBuffer;
import audio.native.MiniAudio.DecoderConfig;
import audio.native.MiniAudio.Decoder;
import cpp.*;

@:allow(audio.native.AudioNode)
@:native('AudioSourceHx') // rename to avoid the collision with AudioSource in C
class AudioSource {

    final nativeSource: Star<NativeAudioSource>;
    final decoderConfig: DecoderConfig;

    function new(context: AudioContext) {
        cpp.vm.Gc.setFinalizer(this, Function.fromStaticFunction(finalizer));
        nativeSource = NativeAudioSource.create(context);
        
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
        NativeAudioSource.destroy(instance.nativeSource);
    }

}

@:allow(audio.native.AudioContext)
class FileAudioSource extends AudioSource {

    function new(context: AudioContext, path: String) {
        super(context);
        var result = nativeSource.maDecoder.initFile(path, Native.addressOf(decoderConfig));
        if (result != SUCCESS) {
            throw 'Failed to initialize an audio file decoder: $result';
        }
    }

}

@:allow(audio.native.AudioContext)
class BufferAudioSource extends AudioSource {

    function new(context: AudioContext, buffer: ArrayBuffer) {
        super(context);
        var result = nativeSource.maDecoder.initMemory(cast buffer.toCPointer(), buffer.byteLength, Native.addressOf(decoderConfig));
        if (result != SUCCESS) {
            throw 'Failed to initialize an buffer decoder: $result';
        }
    }

}

@:include('./native.h')
@:sourceFile('./native.c')
@:native('AudioSource') @:unreflective
@:structAccess
@:access(audio.native.AudioContext)
extern class NativeAudioSource {

    var maDecoder: Star<Decoder>;
    // var mutex: Mutex;

    @:native('~AudioSource')
    function free(): Void;

    @:native('new AudioSource')
    static function alloc(): Star<NativeAudioSource>;

    static inline function create(context: AudioContext): Star<NativeAudioSource> {
        var instance = alloc();
        instance.maDecoder = MiniAudio.Decoder.alloc();
        // @! mutex create
        return instance;
    }

    static inline function destroy(instance: NativeAudioSource): Void {
        instance.maDecoder.uninit();
        instance.maDecoder.free();
        instance.free();
    }

}