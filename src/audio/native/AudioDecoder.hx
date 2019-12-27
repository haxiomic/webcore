package audio.native;

import cpp.*;
import audio.native.MiniAudio.DecoderConfig;

class AudioDecoder {

    public final maDecoder: Star<MiniAudio.Decoder>;
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
        cpp.vm.Gc.setFinalizer(this, Function.fromStaticFunction(finalizer));
    }

    static function finalizer(instance: AudioDecoder) {
        #if debug
        Stdio.printf("%s\n", "[debug] AudioDecoder.finalizer()");
        #end
        instance.maDecoder.uninit();
        instance.maDecoder.free();
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

        var result = maDecoder.initFile(path, Native.addressOf(config));
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
        var result = maDecoder.initMemory(bytesAddress, bytes.length, Native.addressOf(config));
        if (result != SUCCESS) {
            throw 'Failed to initialize a FileBytesDecoder: $result';
        }
    }

}