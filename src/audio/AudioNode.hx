package audio;

#if js

typedef AudioNode = js.html.audio.AudioNode;
typedef AudioScheduledSourceNode = js.html.audio.AudioScheduledSourceNode;
typedef AudioBufferSourceNode = js.html.audio.AudioBufferSourceNode;

#else

import cpp.*;
import audio.native.AudioDecoder;
import audio.native.NativeAudioSource;

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

private typedef PcmTransformFunction<T> = Callable<(data: Star<T>, nChannels: UInt32, frameCount: UInt32, schedulingCurrentFrameBlock: UInt64, interleavedPcmSamples: RawPointer<Float32>) -> Void>;

@:access(audio.AudioContext)
private class PcmTransform {
    
    /**
        This is called from the unmanaged audio thread. It's critical that no haxe-allocation or haxe vm interaction occurs here
        @! maybe move this and PcmTransformData to C
    **/
    @:noDebug static public function readFramesCallback<T>(source: Star<NativeAudioSource>, nChannels: UInt32, frameCount: UInt64, schedulingCurrentFrameBlock: UInt64, interleavedSamples: Star<Float32>): UInt64 {
        var readFramesData: Star<PcmTransformData<T>> = cast source.getUserData();
        var framesRead = AudioContext.mixSources(readFramesData.nativeSourceList, nChannels, frameCount, schedulingCurrentFrameBlock, interleavedSamples);
        // apply user transform to frames read
        readFramesData.transformFunction(readFramesData.transformDataStar, nChannels, framesRead, schedulingCurrentFrameBlock, cast interleavedSamples);
        return framesRead;
    }

}

/**
    `transformFunction` is executed on the audio thread, mutex locking must be used is the transform data is changed from the haxe thread
    Additionally, it's critical no haxe-allocation or vm interaction occurs within `transformFunction`.
**/
@:generic private class PcmTransformNode<T> extends AudioNode {

    // we pass the address to these fields as function data (not their values)
    final readFramesData: PcmTransformData<T>;

    public function new(context: AudioContext, audioThreadTransformFunction: PcmTransformFunction<T>, transformData: T) {
        super(context);
        
        this.readFramesData = new PcmTransformData(Pointer.fromHandle(this.nativeSourceList), audioThreadTransformFunction, transformData);

        this.nativeSource.setUserData(cast Native.addressOf(this.readFramesData));
        this.nativeSource.setReadFramesCallback(Function.fromStaticFunction(PcmTransform.readFramesCallback));
        this.nativeSource.setActive(true);
    }

}

@:generic private class PcmTransformData<T> {

    public final nativeSourceList: Star<NativeAudioSourceList>;
    public final transformFunction: PcmTransformFunction<T>;
    public final transformDataStar: Star<T>;
    final transformData: T;

    public function new(
        nativeSourceList: Pointer<NativeAudioSourceList>,
        transformFunction: PcmTransformFunction<T>,
        transformData: T
    ) {
        this.nativeSourceList = nativeSourceList.ptr;
        this.transformFunction = transformFunction;
        this.transformData = transformData;
        this.transformDataStar = cast Native.addressOf(this.transformData); // must be this.transformData
    }

}

class GainNode extends PcmTransformNode<Float> {

    public function new(context: AudioContext,  ?options: {
        var ?gain: Float;
    }) {
        var gainValue = options != null && options.gain != null ? options.gain : 1.0;
        super(context, Function.fromStaticFunction(applyGain), gainValue);
    }

    @:noDebug static function applyGain(gainStar: Star<Float>, nChannels: UInt32, frameCount: UInt32, schedulingCurrentFrameBlock: UInt64, interleavedPcmSamples: RawPointer<Float32>) {
        var gain: Float = Native.star(gainStar);
        // we use inline C++ here because a for-loop will vectorize better than hxcpp's while-loop
        untyped __cpp__('
            int totalSamples = frameCount*nChannels;
            for (int i = 0; i < totalSamples; i++) {
                {0}[i] *= {1};
            }
        ', interleavedPcmSamples, gain);
    }

}

#end