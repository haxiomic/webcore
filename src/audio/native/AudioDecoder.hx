package audio.native;

import cpp.*;
import audio.native.MiniAudio.DecoderConfig;

@:native('audio.native.AudioDecoderHx')
class AudioDecoder {

    public final nativeAudioDecoder: Star<NativeAudioDecoder>;
    public final context: AudioContext;
    final config: DecoderConfig;

    function new(context: AudioContext) {
        this.context = context;
        final maDevice = context.maDevice;
        this.config  = MiniAudio.DecoderConfig.init(
            maDevice.playback.format,
            maDevice.playback.channels,
            maDevice.sampleRate
        );
        this.nativeAudioDecoder = NativeAudioDecoder.create(context.maDevice.pContext, config);
        cpp.vm.Gc.setFinalizer(this, Function.fromStaticFunction(finalizer));
    }

    public inline function getLengthInPcmFrames(): UInt64 {
        return nativeAudioDecoder.getLengthInPcmFrames();
    }

    public inline function seekToPcmFrame(frameIndex: UInt64): MiniAudio.Result {
        return nativeAudioDecoder.seekToPcmFrame(frameIndex);
    }

    static function finalizer(instance: AudioDecoder) {
        #if debug
        Stdio.printf("%s\n", "[debug] AudioDecoder.finalizer()");
        #end
        NativeAudioDecoder.destroy(instance.nativeAudioDecoder);
    }

}

class FileDecoder extends AudioDecoder {

    public final path: String;

    /**
        @throws string
    **/
    public function new(context: AudioContext, path: String) {
        super(context);
        this.path = path;

        var result = this.nativeAudioDecoder.maDecoder.init_file(path, Native.addressOf(config));
        if (result != SUCCESS) {
            throw 'Failed to initialize a FileDecoder: $result';
        }
    }

}

class FileBytesDecoder extends AudioDecoder {

    // keep a reference so bytes doesn't get cleared by the GC
    final bytes: haxe.io.Bytes;
    
    /**
        @throws string
    **/
    public function new(context: AudioContext, fileBytes: haxe.io.Bytes, copyBytes: Bool = true) {
        super(context);
        bytes = copyBytes ? fileBytes.sub(0, fileBytes.length) : fileBytes;
        // copy bytes

        var bytesAddress: ConstStar<cpp.Void> = cast cpp.NativeArray.address(bytes.getData(), 0).raw;
        var result = this.nativeAudioDecoder.maDecoder.init_memory(bytesAddress, bytes.length, Native.addressOf(config));
        if (result != SUCCESS) {
            throw 'Failed to initialize a FileBytesDecoder: $result';
        }
    }

}

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('NativeAudioDecoder') @:unreflective
@:structAccess
extern class NativeAudioDecoder {

    var maDecoder: Star<MiniAudio.Decoder>;
    var lock: Star<MiniAudio.Mutex>;
    var frameIndex: UInt64;

    inline function readPcmFrames(pFramesOut: Star<cpp.Void>, frameCount: UInt64): UInt64 {
        return untyped __global__.NativeAudioDecoder_readPcmFrames((this: Star<NativeAudioDecoder>), pFramesOut, frameCount);
    }

    inline function getLengthInPcmFrames(): UInt64 {
        return untyped __global__.NativeAudioDecoder_getLengthInPcmFrames((this: Star<NativeAudioDecoder>));
    }

    inline function seekToPcmFrame(frameIndex: UInt64): MiniAudio.Result {
        return untyped __global__.NativeAudioDecoder_seekToPcmFrame((this: Star<NativeAudioDecoder>), frameIndex);
    }

    @:native('~NativeAudioDecoder')
    function free(): Void;

    @:native('new NativeAudioDecoder')
    static function alloc(): Star<NativeAudioDecoder>;

    static inline function create(maContext: Star<MiniAudio.Context>, config: Star<MiniAudio.DecoderConfig>): Star<NativeAudioDecoder> {
        var instance = alloc();
        instance.frameIndex = 0;

        instance.lock = MiniAudio.Mutex.alloc();
        instance.lock.init(maContext);

        instance.maDecoder = MiniAudio.Decoder.alloc();
        
        return instance;
    }

    static inline function destroy(instance: NativeAudioDecoder): Void {
        instance.free();

        instance.lock.uninit();
        instance.lock.free();

        instance.maDecoder.uninit();
        instance.maDecoder.free();
    }

}