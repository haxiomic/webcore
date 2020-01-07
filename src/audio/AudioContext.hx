package audio;

#if js

typedef AudioContext = js.html.audio.AudioContext;

#else

import cpp.*;

import audio.native.AudioDecoder;
import audio.native.MiniAudio.Device;
import audio.native.MiniAudio.DeviceConfig;

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:allow(audio.AudioNode)
@:allow(audio.native.AudioDecoder)
class AudioContext {

    public final destination: AudioNode;
    public var state (get, null): AudioContextState;

    final maDevice: Star<Device>;
    var _state: AudioContextState = SUSPENDED;

    public function new(?options: {
        ?sampleRate: Int,
        ?latencyHint: LatencyHint, // default "interactive"
    }) {
        if (options == null) {
            options = {};
        }

        // @! should be manually creating the context here

        maDevice = Device.alloc();

        var deviceConfig = DeviceConfig.init(PLAYBACK);
        deviceConfig.sampleRate = options.sampleRate != null ? options.sampleRate : 0;
        deviceConfig.playback.format = F32;
        deviceConfig.performanceProfile = options.latencyHint != "interactive" ? CONSERVATIVE : LOW_LATENCY;
        deviceConfig.dataCallback = untyped __global__.Audio_mixSources;

        // initialize device
        var initResult = maDevice.init(null, Native.addressOf(deviceConfig));
        if (initResult != SUCCESS || maDevice == null) {
            throw 'Failed to initialize miniaudio device: $initResult';
        }

        destination = new AudioNode(this);

        maDevice.pUserData = cast destination.nativeSourceList;

        cpp.vm.Gc.setFinalizer(this, Function.fromStaticFunction(finalizer));

        resume();
    }

    public function resume() {
        if (state == SUSPENDED) {
            maDevice.start();
            gcReference.add(this);
            _state = RUNNING;
        }
    }

    public function suspend() {
        if (state == RUNNING) {
            maDevice.stop();
            gcReference.remove(this);
            _state = SUSPENDED;
        }
    }

    public function close() {
        this.suspend();
        state = CLOSED;
        // maybe call finalizer but make sure it's not called twice (again by the GC) because this will be invalid
    }

    public function createBufferSource() {
        return new AudioNode.AudioBufferSourceNode(this);
    }

    public function decodeAudioData(audioFileBytes: haxe.io.BytesData, ?successCallback: AudioBuffer -> Void, ?errorCallback: String -> Void): Void {
        try {
            // decode file into raw pcm frame bytes
            var tmpDecoder = new FileBytesDecoder(this, haxe.io.Bytes.ofData(audioFileBytes), false);
            var bytes = tmpDecoder.getInterleavedPcmFrames(0);
            var audioBuffer = new AudioBuffer(bytes);
            if (successCallback != null) {
                successCallback(audioBuffer);
            }
        } catch (e: String) {
            if (errorCallback != null) {
                errorCallback(e);
            }
        }
    }

    function get_state() {
        return this._state;
    }

    static var gcReference = new List<AudioContext>();

    static function finalizer(instance: AudioContext) {
        #if debug
        Stdio.printf("%s\n", "[debug] AudioContext.finalizer()");
        #end
        
        instance.maDevice.uninit();
        instance.maDevice.free();
        // @! should uninit context too
    }

}

enum abstract AudioContextState(String) to String from String {
    var SUSPENDED = "suspended";
    var RUNNING = "running";
    var CLOSED = "closed";
}

enum abstract LatencyHint(String) to String from String {
    var BALANCED = "balanced";
    var INTERACTIVE = "interactive";
    var PLAYBACK = "playback";
}

#end