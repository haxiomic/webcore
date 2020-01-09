package audio.native;

import cpp.*;

@:native('audio.native.AudioDecoderHx')
class AudioDecoder {

    public final nativeAudioDecoder: Star<NativeAudioDecoder>;
    public final context: AudioContext;
    public final format: MiniAudio.Format;
    public final sampleRate: UInt32;
    public final channels: UInt32;

    public var frameIndex (get, never): UInt64;
    public var currentTime_s (get, never): Float;

    final config: MiniAudio.DecoderConfig;

    function new(context: AudioContext) {
        this.context = context;
        final maDevice = context.maDevice;
        this.config  = MiniAudio.DecoderConfig.init(
            maDevice.playback.format,
            maDevice.playback.channels,
            maDevice.sampleRate
        );

        this.format = this.config.format;
        this.sampleRate = this.config.sampleRate;
        this.channels = this.config.channels;

        this.nativeAudioDecoder = NativeAudioDecoder.create(context.maDevice.pContext, config);
        cpp.vm.Gc.setFinalizer(this, Function.fromStaticFunction(finalizer));
    }

    public inline function getLengthInPcmFrames(): UInt64 {
        return nativeAudioDecoder.getLengthInPcmFrames();
    }

    /**
        Reads PCM frames into a single buffer. The data format for each sample matches the `format` field of this instance. Multiple channels are interleaved
        For example, 3 samples with two channels: [C1 C2 C1 C2 C1 C2]

        By default the sample data type will be float32
    **/
    public inline function getInterleavedPcmFrames(startFrameIndex: UInt64 = 0, ?frameCount: UInt64): haxe.io.Bytes {
        var initialFrameIndex = frameIndex;
        var sourceLength = getLengthInPcmFrames();
        var remainingFrames = sourceLength - startFrameIndex;
        var framesToRead: UInt64 = if (frameCount == null) {
            remainingFrames;
        } else {
            frameCount < remainingFrames ? frameCount : remainingFrames;
        }

        var bytesPerFrame = MiniAudio.get_bytes_per_frame(format, channels);
        var totalBytes: UInt64 = cast bytesPerFrame * framesToRead;
        var bytes = haxe.io.Bytes.alloc(totalBytes);
        var bytesAddress: Star<cpp.Void> = cast cpp.NativeArray.address(bytes.getData(), 0).raw;
        
        seekToPcmFrame(startFrameIndex);
        nativeAudioDecoder.readPcmFrames(bytesAddress, framesToRead);
        seekToPcmFrame(initialFrameIndex);

        return bytes;
    } 

    public inline function seekToPcmFrame(frameIndex: UInt64): MiniAudio.Result {
        return nativeAudioDecoder.seekToPcmFrame(frameIndex);
    }

    inline function get_frameIndex() {
        return nativeAudioDecoder.getFrameIndex();
    }

    inline function get_currentTime_s() {
        return frameIndex / config.sampleRate;
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

/**
    Create a decoder to read PCM samples from the bytes of a compressed audio file (e.g. mp3)
**/
class FileBytesDecoder extends AudioDecoder {

    // keep a reference so bytes doesn't get cleared by the GC
    final bytes: haxe.io.Bytes;
    
    /**
        @throws string
    **/
    public function new(context: AudioContext, fileBytes: haxe.io.Bytes, copyBytes: Bool = true) {
        super(context);
        // copy bytes by default
        bytes = copyBytes ? fileBytes.sub(0, fileBytes.length) : fileBytes;
        var bytesAddress: ConstStar<cpp.Void> = cast cpp.NativeArray.address(bytes.getData(), 0).raw;
        var result = this.nativeAudioDecoder.maDecoder.init_memory(bytesAddress, bytes.length, Native.addressOf(config));
        if (result != SUCCESS) {
            throw 'Failed to initialize a FileBytesDecoder: $result';
        }
    }

}

/**
    Create a decoder to read PCM (pulse-code modulation) samples from a buffer of interleaved PCM samples
**/
class PcmBufferDecoder extends AudioDecoder {

    // keep a reference so bytes doesn't get cleared by the GC
    final bytes: haxe.io.Bytes;
    
    /**
        @throws string
    **/
    public function new(
        context: AudioContext,
        interleavedPcmBytes: haxe.io.Bytes,
        interleavedPcmBytesConfig: {
            final channels: UInt32;
            final sampleRate: UInt32;
        },
        copyBytes: Bool = true
    ) {
        super(context);
        // copy bytes by default
        bytes = copyBytes ? interleavedPcmBytes.sub(0, interleavedPcmBytes.length) : interleavedPcmBytes;
        var bytesAddress: ConstStar<cpp.Void> = cast cpp.NativeArray.address(bytes.getData(), 0).raw;

        var inputConfig = MiniAudio.DecoderConfig.init(
            F32,
            interleavedPcmBytesConfig.channels,
            interleavedPcmBytesConfig.sampleRate
        );

        var result = this.nativeAudioDecoder.maDecoder.init_memory_raw(bytesAddress, bytes.length, Native.addressOf(inputConfig), Native.addressOf(config));
        if (result != SUCCESS) {
            throw 'Failed to initialize a FileBytesDecoder: $result';
        }
    }

}

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('AudioDecoder') @:unreflective
@:structAccess
extern class NativeAudioDecoder {

    var maDecoder: Star<MiniAudio.Decoder>;
    var lock: Star<MiniAudio.Mutex>;
    private var frameIndex: UInt64;

    inline function readPcmFrames(pFramesOut: Star<cpp.Void>, frameCount: UInt64): UInt64 {
        return untyped __global__.AudioDecoder_readPcmFrames((this: Star<NativeAudioDecoder>), frameCount, pFramesOut);
    }

    inline function getLengthInPcmFrames(): UInt64 {
        return untyped __global__.AudioDecoder_getLengthInPcmFrames((this: Star<NativeAudioDecoder>));
    }

    inline function seekToPcmFrame(frameIndex: UInt64): MiniAudio.Result {
        return untyped __global__.AudioDecoder_seekToPcmFrame((this: Star<NativeAudioDecoder>), frameIndex);
    }

    inline function getFrameIndex(): UInt64 {
        return lock.locked(() -> this.frameIndex);
    }

    @:native('~AudioDecoder')
    function free(): Void;

    @:native('new AudioDecoder')
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