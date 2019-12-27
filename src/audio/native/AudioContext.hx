package audio.native;

import audio.native.AudioSource.FileAudioSource;
import cpp.*;

@:include('./native.h')
@:sourceFile('./native.m')
@:allow(audio.native.AudioNode)
@:allow(audio.native.AudioSource)
class AudioContext {

    public final destination: AudioNode;

    final maDevice: Star<MiniAudio.Device>;
    var started: Bool = false;
    var activeSources = new List<AudioSource>();

    public function new(?options: {
        ?sampleRate: Int,
        ?lowLatency: Bool,
    }) {
        if (options == null) {
            options = {};
        }

        maDevice = MiniAudio.Device.alloc();

        var deviceConfig = MiniAudio.DeviceConfig.init(PLAYBACK);
        deviceConfig.sampleRate = options.sampleRate != null ? options.sampleRate : 0;
        deviceConfig.playback.format = F32;
        deviceConfig.performanceProfile = options.lowLatency == false ? CONSERVATIVE : LOW_LATENCY;
        deviceConfig.dataCallback = untyped __global__.Audio_mixSources;

        // initialize device
        var initResult = maDevice.init(null, Native.addressOf(deviceConfig));
        if (initResult != SUCCESS) {
            throw 'Failed to initialize miniaudio device: $initResult';
        }

        cpp.vm.Gc.setFinalizer(this, Function.fromStaticFunction(finalizer));

        destination = new AudioNode(this);

        maDevice.pUserData = cast destination.nativeSourceList;

        resume();
    }

    public function resume() {
        if (!started) {
            maDevice.start();
            gcReference.add(this);
            started = true;
        }
    }

    public function suspend() {
        if (started) {
            maDevice.stop();
            gcReference.remove(this);
            started = false;
        }
    }

    public function createFileSource(path: String): AudioNode {
        return new AudioNode(this, new FileAudioSource(this, path));
    }

    public function createBufferSource(): AudioNode.AudioBufferSourceNode {
        return new AudioNode.AudioBufferSourceNode(this);
    }

    public function decodeAudioData(audioData: haxe.io.Bytes, ?successCallback: AudioBuffer -> Void, ?errorCallback: String -> Void): Void {
        try {
            var audioBuffer = new AudioSource.BufferAudioSource(this, audioData);
            if (successCallback != null) {
                successCallback(audioBuffer);
            }
        } catch (e: String) {
            if (errorCallback != null) {
                errorCallback(e);
            }
        }
    }

    static var gcReference = new List<AudioContext>();

    static function finalizer(instance: AudioContext) {
        #if debug
        Stdio.printf("%s\n", "[debug] AudioContext.finalizer()");
        #end

        instance.maDevice.uninit();
        instance.maDevice.free();
    }

}