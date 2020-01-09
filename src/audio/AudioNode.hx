package audio;

#if js

typedef AudioNode = js.html.audio.AudioNode;
typedef AudioScheduledSourceNode = js.html.audio.AudioScheduledSourceNode;
typedef AudioBufferSourceNode = js.html.audio.AudioBufferSourceNode;

#else

import cpp.*;
import audio.native.AudioDecoder;
import audio.native.NativeAudioSource;
import audio.native.MiniAudio;

@:allow(audio.AudioContext)
class AudioNode {

    public final context: AudioContext;
    public var numberOfInputs(get, null): Int;
    public var numberOfOutputs(get, null): Int;

    var decoder: Null<AudioDecoder>;
    final nativeSource: Star<NativeAudioSource>;

    final nativeSourceList: Star<NativeAudioSourceList>;
    final connectedSources = new List<AudioNode>();
    final connectedDestinations = new List<AudioNode>();

    function new(context: AudioContext, ?decoder: AudioDecoder) {
        this.context = context;
        this.nativeSource = NativeAudioSource.create(context.maDevice.pContext);
        this.nativeSourceList = NativeAudioSourceList.create(context.maDevice.pContext);

        if (decoder != null) {
            setDecoder(decoder);
        }

        cpp.vm.Gc.setFinalizer(this, Function.fromStaticFunction(finalizer));
    }

    public function connect(destination: AudioNode) {
        if (!Lambda.has(connectedDestinations, destination)) {
            connectedDestinations.add(destination);
        }
        destination.addSourceNode(this);
    }

    public function disconnect(destination: AudioNode) {
        connectedDestinations.remove(destination);
        destination.removeSourceNode(this);
    }

    function setDecoder(decoder: AudioDecoder) {
        this.decoder = decoder;
        if (nativeSource != null) {
            this.nativeSource.setDecoder(decoder.nativeAudioDecoder);
        }
    }

    function addSourceNode(node: AudioNode) {
        if (!Lambda.has(connectedSources, node)) {
            connectedSources.add(node);
            if (node.nativeSource != null) {
                this.nativeSourceList.add(node.nativeSource);
            }
        }
    }

    function removeSourceNode(node: AudioNode) {
        connectedSources.remove(node);
        if (node.nativeSource != null) {
            this.nativeSourceList.remove(node.nativeSource);
        }
    }

    inline function get_numberOfInputs(): Int {
        return this.connectedSources.length;
    }

    inline function get_numberOfOutputs(): Int {
        return this.connectedDestinations.length;
    }

    static function finalizer(instance: AudioNode) {
        #if debug
        Stdio.printf("%s\n", "[debug] AudioNode.finalizer()");
        #end
        NativeAudioSource.destroy(instance.nativeSource);
        NativeAudioSourceList.destroy(instance.nativeSourceList);
    }

}

@:allow(audio.native.AudioContext)
class AudioScheduledSourceNode extends AudioNode {

    public inline function start() {
        this.nativeSource.setActive(true);
    }

    public inline function stop() {
        this.nativeSource.setActive(false);
    }

}

@:allow(audio.AudioContext)
class AudioBufferSourceNode extends AudioScheduledSourceNode {

    public var loop (get, set): Bool;

    public var buffer (get, set): AudioBuffer;
    var _buffer: AudioBuffer;

    inline function get_buffer(): AudioBuffer {
        return this._buffer;
    }

    inline function set_buffer(b: AudioBuffer): AudioBuffer {
        // create a decoder for this buffer
        var bytesDecoder = new PcmBufferDecoder(context, b.interleavedPcmBytes, {
            channels: b.config.channels,
            sampleRate: b.config.sampleRate
        });
        setDecoder(bytesDecoder);
        return _buffer = b;
    }

    inline function get_loop(): Bool {
        return this.nativeSource.getLoop();
    }

    inline function set_loop(v: Bool): Bool {
        return this.nativeSource.setLoop(v);
    }

}

private typedef PcmTransformFunction<T> = Callable<(data: Star<T>, nChannels: UInt32, frameCount: UInt32, interleavedPcmSamples: RawPointer<Float32>) -> Void>;

@:access(audio.AudioContext)
private class PcmTransform {
    
    /**
        This is called from the unmanaged audio thread. It's critical that no haxe-allocation or haxe vm interaction occurs here
        @! maybe move this to C
    **/
    @:noDebug static public function readFramesCallback<T>(source: Star<NativeAudioSource>, nChannels: UInt32, frameCount: UInt64, schedulingCurrentFrameBlock: UInt64, interleavedSamples: Star<Float32>): UInt64 {
        var readFramesData: Star<PcmTransformData<T>> = cast source.getUserData();
        var framesRead = AudioContext.mixSources(readFramesData.nativeSourceList, nChannels, frameCount, schedulingCurrentFrameBlock, interleavedSamples);
        // apply user transform
        // @! should only apply the transform function to frames that are actually read
        readFramesData.transformFunction(readFramesData.transformData, nChannels, frameCount, cast interleavedSamples);
        return framesRead;
    }

}

@:generic private class PcmTransformNode<T> extends AudioNode {

    // we pass the address to these fields as function data (not their values)
    final readFramesData: PcmTransformData<T>;
    final transformData: T; // used to ensure we have a reference for GC

    public function new(context: AudioContext, transformFunction: PcmTransformFunction<T>, transformData: T) {
        super(context);
        this.transformData = transformData;
        
        this.readFramesData = new PcmTransformData(Pointer.fromHandle(this.nativeSourceList), transformFunction);
        this.readFramesData.transformData = cast Native.addressOf(this.transformData);

        this.nativeSource.setUserData(cast Native.addressOf(this.readFramesData));
        this.nativeSource.setReadFramesCallback(Function.fromStaticFunction(PcmTransform.readFramesCallback));
        this.nativeSource.setActive(true);
    }

}

@:generic private class PcmTransformData<T> {

    public final nativeSourceList: Star<NativeAudioSourceList>;
    public final transformFunction: PcmTransformFunction<T>;
    public var transformData: Star<T>;

    public function new(
        nativeSourceList: Pointer<NativeAudioSourceList>,
        transformFunction: PcmTransformFunction<T>
    ) {
        this.nativeSourceList = nativeSourceList.ptr;
        this.transformFunction = transformFunction;
    }

}

/**
    Experimental; not ready to use
**/
class GainNode extends PcmTransformNode<GainData> {

    public function new(context: AudioContext,  ?options: {
        var ?gain: Float;
    }) {
        options = options == null ? {} : options;
        var data = new GainData(context);
        data.set(@:fixed {
            gain: options.gain != null ? options.gain : 1.0,
        });
        super(context, Function.fromStaticFunction(applyGain), data);
    }

    @:noDebug static function applyGain(gainData: Star<GainData>, nChannels: UInt32, frameCount: UInt32, interleavedPcmSamples: RawPointer<Float32>) {
        // @! this is introducing too much hxcpp code onto the audio thread. Should not use this approach
        var gain = gainData.get().gain;
        Stdio.printf("applyGain(%f) %d %d %p\n", gain, nChannels, frameCount, interleavedPcmSamples);
        // @! should use inline C++ for better auto-vectorization
        for (i in 0...frameCount*nChannels) {
            interleavedPcmSamples[i] *= gain;
        }
    }

}

@:access(audio.AudioContext)
@:generic private class LockedValue<T> {

    final mutex: Star<Mutex>;

    var value: T;
    
    public function new(context: AudioContext) {
        this.mutex = Mutex.alloc();
        this.mutex.init(context.maDevice.pContext);
        cpp.vm.Gc.setFinalizer(this, Function.fromStaticFunction(LockedValueFinalizer.finalizer));
    }

    @:noDebug public inline function get(): T {
        return mutex.locked(() -> value);
    }

    @:noDebug public inline function set(v: T): T {
        return mutex.locked(() -> value = v);
    }

}

@:access(audio.LockedValue)
private class LockedValueFinalizer {
    static public function finalizer<T>(instance: LockedValue<T>) {
        #if debug
        Stdio.printf("%s\n", "[debug] LockedValue.finalizer()");
        #end
        instance.mutex.uninit();
        instance.mutex.free();
    }
}

typedef GainData = LockedValue<{gain: Float}>;

// private class GainData {

//     public var gain: Float = 1.0; // @! needs mutex locked access
//     public function new(gain = 1.0) {
//         this.gain = gain;
//         cpp.vm.Gc.setFinalizer(this, Function.fromStaticFunction(finalizer));
//     }

//     static function finalizer(instance: GainData) {
//         #if debug
//         Stdio.printf("%s\n", "[debug] GainData.finalizer()");
//         #end
//     }

// }

#end