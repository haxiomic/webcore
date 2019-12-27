package audio.native;

import cpp.*;
import audio.native.MiniAudio.DecoderConfig;

class AudioDecoder {

    public final maDecoder: Star<MiniAudio.Decoder>;
    public final maDecoderLock: Star<MiniAudio.Mutex>;
    public final context: AudioContext;
    final config: DecoderConfig;

    function new(context: AudioContext) {
        this.context = context;
        var maDevice = context.maDevice;
        config = MiniAudio.DecoderConfig.init(
            maDevice.playback.format,
            maDevice.playback.channels,
            maDevice.sampleRate
        );
        maDecoder = MiniAudio.Decoder.alloc();

        maDecoderLock = MiniAudio.Mutex.alloc();
        maDecoderLock.init(context.maDevice.pContext);

        cpp.vm.Gc.setFinalizer(this, Function.fromStaticFunction(finalizer));
    }

    public function getLengthInPcmFrames(): UInt64 {
        maDecoderLock.lock();
        var length = maDecoder.get_length_in_pcm_frames();
        maDecoderLock.unlock();
        return length;
    }

    public function seekToPcmFrame(frameIndex: UInt64): MiniAudio.Result {
        maDecoderLock.lock();
        var result = maDecoder.seek_to_pcm_frame(frameIndex);
        maDecoderLock.unlock();
        return result;
    }

    static function finalizer(instance: AudioDecoder) {
        #if debug
        Stdio.printf("%s\n", "[debug] AudioDecoder.finalizer()");
        #end
        instance.maDecoder.uninit();
        instance.maDecoder.free();
        instance.maDecoderLock.uninit();
        instance.maDecoderLock.free();
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

        var result = maDecoder.init_file(path, Native.addressOf(config));
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
    public function new(context: AudioContext, fileBytes: haxe.io.Bytes) {
        super(context);
        // copy bytes
        bytes = fileBytes.sub(0, fileBytes.length);

        var bytesAddress: ConstStar<cpp.Void> = cast cpp.NativeArray.address(bytes.getData(), 0).raw;
        var result = maDecoder.init_memory(bytesAddress, bytes.length, Native.addressOf(config));
        if (result != SUCCESS) {
            throw 'Failed to initialize a FileBytesDecoder: $result';
        }
    }

}