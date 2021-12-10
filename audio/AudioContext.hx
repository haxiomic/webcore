package audio;

#if js

// Amazingly Safari 13 in 2020 does not support WebAudio without a prefix
// this abstract checks for `webkitAudioContext` if `AudioContext` is not available
@:forward
abstract AudioContext(js.html.audio.AudioContext) {

    public inline function new(?contextOptions: js.html.audio.AudioContextOptions) {
        if (js.Syntax.typeof(js.html.audio.AudioContext) != 'undefined') {
            this = new js.html.audio.AudioContext(contextOptions);
        } else if (js.Syntax.typeof(untyped webkitAudioContext) != 'undefined') {
            this = js.Syntax.code('new webkitAudioContext({0})', contextOptions);
        } else {
            throw 'Browser does not support WebAudio';
        }
    }

}

#else

import cpp.*;

import typedarray.ArrayBuffer;
import audio.native.AudioDecoder;
import audio.native.NativeAudioNode.NativeAudioNodeList;
import audio.native.MiniAudio;
import audio.native.LockedValue;

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:allow(audio.AudioNode)
@:allow(audio.native.AudioDecoder)
class AudioContext {

    public final destination: AudioDestinationNode;
    public var currentTime (get, null): Float;
    public var sampleRate (get, null): Float;
    public var state (get, null): AudioContextState;

    final maDevice: Star<Device>;
    final userData: DeviceUserData;
    var _state: AudioContextState = SUSPENDED;

    public function new(?contextOptions: {
        ?sampleRate: Int,
        ?latencyHint: LatencyHint, // default "interactive"
    }) {
        if (contextOptions == null) {
            contextOptions = {};
        }

        // @! explore if it's better to manually create the context here (currently it's created by miniaudio when the device is initialized)

        maDevice = Device.alloc();

        var deviceConfig = DeviceConfig.init(PLAYBACK);
        deviceConfig.sampleRate = contextOptions.sampleRate != null ? contextOptions.sampleRate : 0;
        deviceConfig.playback.format = F32;
        deviceConfig.performanceProfile = switch contextOptions.latencyHint {
            case null, INTERACTIVE: LOW_LATENCY;
            case PLAYBACK, BALANCED: CONSERVATIVE; 
            
        };
        deviceConfig.dataCallback = Function.fromStaticFunction(audioThread_deviceDataCallbackMixSources);

        // initialize device
        var initResult = maDevice.init(null, Native.addressOf(deviceConfig));
        if (initResult != SUCCESS || maDevice == null) {
            throw 'Failed to initialize miniaudio device: $initResult';
        }

        destination = new AudioDestinationNode(this);

        userData = new DeviceUserData(this, Pointer.fromStar(destination.nativeNodeList));

        maDevice.pUserData = cast Native.addressOf(userData);

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

    /**
        Creates a new, empty `AudioBuffer` object, which can then be populated by data and played via an `AudioBufferSourceNode`.
        @throws String
    **/
    public function createBuffer(numberOfChannels: Int, frameCount: Int, sampleRate: Float): AudioBuffer {
        // allocate bytes
        var bytesPerFrame = MiniAudio.get_bytes_per_frame(F32, numberOfChannels);
        var totalBytes = bytesPerFrame * frameCount;
        var bytes = haxe.io.Bytes.alloc(totalBytes);
        // we should initialize to 0 to match WebAudio behavior
        bytes.fill(0, bytes.length, 0);
        return new AudioBuffer(bytes, @:fixed {
            channels: numberOfChannels,
            sampleRate: Std.int(sampleRate)
        });
    }
    
    /**
        Creates an `AudioBufferSourceNode`, which can be used to play and manipulate audio data contained within an `AudioBuffer` object. `AudioBuffer`s are created using `AudioContext.createBuffer` or returned by `AudioContext.decodeAudioData` when it successfully decodes an audio track.
        @throws String
    **/
    public function createBufferSource() {
        return new AudioBufferSourceNode(this);
    }

    /**
        Creates a `GainNode`, which can be used to control the overall volume of the audio graph.
        @throws DOMError
    **/
    public function createGain() {
        return new GainNode(this);
    }

    public function decodeAudioData(audioFileBytes: ArrayBuffer, ?successCallback: AudioBuffer -> Void, ?errorCallback: String -> Void): Void {
        var copiedBytes = audioFileBytes.slice(0); // we must copy because these bytes are read from another thread
        sys.thread.Thread.create(() -> {
            try {
                // decode file into raw pcm frame bytes
                var tmpDecoder = new FileBytesDecoder(this, copiedBytes, false);
                var bytes = tmpDecoder.getInterleavedPcmFrames(0);
                var audioBuffer = new AudioBuffer(bytes, tmpDecoder);
                if (successCallback != null) {
                    haxe.EntryPoint.runInMainThread(() -> successCallback(audioBuffer));
                }
            } catch (e: String) {
                if (errorCallback != null) {
                    haxe.EntryPoint.runInMainThread(() -> errorCallback(e));
                }
            }
        });
    }

    inline function get_state() {
        return this._state;
    }

    inline function get_currentTime() {
        var schedulingCurrentFrameBlock = userData.schedulingCurrentFrameBlock.get();
        return schedulingCurrentFrameBlock / sampleRate;
    }

    inline function get_sampleRate() {
        return this.maDevice.sampleRate;
    }

    static var gcReference = new List<AudioContext>();

    /**
        Device data callback to mix its source list (stored in user data) to the output buffer
        *You should not perform any haxe allocation here as it is executed on the unmanaged audio thread*
        The `@:noDebug` meta here is critical to prevent generation of hxcpp's thread-unsafe stack tracking code 
    **/
    @:noDebug
    static function audioThread_deviceDataCallbackMixSources(maDevice: Star<Device>, output: Star<cpp.Void>, input: ConstStar<cpp.Void>, frameCount: UInt32) {
        var userData: DeviceUserData = (cast maDevice.pUserData: Star<DeviceUserData>);

        // double cast to workaround compiler issue, see HaxeFoundation/haxe/pull/9194
        var outputF32: RawPointer<Float32> = cast (cast output: Star<Float32>);

        userData.schedulingCurrentFrameBlock.mutex.lock();
        var schedulingCurrentFrameBlock: Int64 = userData.schedulingCurrentFrameBlock.getUnsafe();
        userData.schedulingCurrentFrameBlock.mutex.unlock();

        // the audio graph is processed in blocks of 128 frames called a 'render-quantum'
        // https://webaudio.github.io/web-audio-api/#render-quantum

        final quantaLength = 128;
        var framesRemaining = frameCount;

        while (framesRemaining > 0) {
            var framesToRead = framesRemaining > quantaLength ? quantaLength : framesRemaining;

            // offset output buffer by current samples read
            var framesRead = frameCount - framesRemaining;
            var samplesRead = framesRead * maDevice.playback.channels;
            var quantaOutput = Native.addressOf(outputF32[samplesRead]);

            mixSources(userData.nativeNodeList, maDevice.playback.channels, framesToRead, schedulingCurrentFrameBlock, quantaOutput);

            framesRemaining -= framesToRead;
            // schedulingCurrentFrameBlock += (cast framesToRead: Int64);
            schedulingCurrentFrameBlock = untyped __cpp__('{0} + {1}', schedulingCurrentFrameBlock, framesToRead);

            // update shared current block variable atomically
            userData.schedulingCurrentFrameBlock.mutex.lock();
            userData.schedulingCurrentFrameBlock.setUnsafe(schedulingCurrentFrameBlock);
            userData.schedulingCurrentFrameBlock.mutex.unlock();
        }
    }

    @:noDebug
    static inline function mixSources(sources: Star<NativeAudioNodeList>, nChannels: UInt32, frameCount: UInt32, schedulingCurrentFrameBlock: Int64, output: Star<Float32>): UInt32 {
        return untyped __global__.Audio_mixSources(sources, nChannels, frameCount, schedulingCurrentFrameBlock, output);
    }

    static function finalizer(instance: AudioContext) {
        #if debug
        Stdio.printf("%s\n", "[debug] AudioContext.finalizer()");
        #end
        
        instance.maDevice.uninit();
        instance.maDevice.free();
        // @! should maybe uninit context too
    }

}

class DeviceUserData {

    public final nativeNodeList: Star<NativeAudioNodeList>;
    public final schedulingCurrentFrameBlock: audio.native.LockedValue<Int64>;

    public function new(context: AudioContext, nativeNodeList: Pointer<NativeAudioNodeList>) {
        this.nativeNodeList = nativeNodeList.ptr;
        this.schedulingCurrentFrameBlock = new LockedValue(context);
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