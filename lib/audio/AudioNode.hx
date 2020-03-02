package audio;

#if js

typedef AudioNode = js.html.audio.AudioNode;

#else

import cpp.*;
import audio.native.AudioDecoder;
import audio.native.NativeAudioNode;

@:allow(audio.AudioContext)
@:native('audio.AudioNodeHx')
class AudioNode {

    public final context: AudioContext;
    public var numberOfInputs (default, null): Int;
    public var numberOfOutputs (default, null): Int;

    var decoder: Null<AudioDecoder>;
    final nativeNode: Star<NativeAudioNode>;

    final nativeNodeList: Star<NativeAudioNodeList>;

    final connectedDestinations = new List<AudioNode>();
    final activeSources = new List<AudioNode>();

    function new(context: AudioContext, ?decoder: AudioDecoder) {
        this.context = context;
        this.nativeNode = NativeAudioNode.create(context.maDevice.pContext);
        this.nativeNodeList = NativeAudioNodeList.create(context.maDevice.pContext);

        numberOfOutputs = 0;
        numberOfInputs = 0;

        if (decoder != null) {
            setDecoder(decoder);
        }

        cpp.vm.Gc.setFinalizer(this, Function.fromStaticFunction(finalizer));
    }

    public function connect(destination: AudioNode) {
        // the node isn't considered a live source of the destination until it's activated
        if (!Lambda.has(connectedDestinations, destination)) {
            connectedDestinations.add(destination);
        }
        return destination;
    }

    public function disconnect(?destination: AudioNode) {
        if (destination == null) {
            // disconnect from all connected destinations
            for (node in connectedDestinations) {
                node.removeActiveSourceNode(this);
            }
            connectedDestinations.clear();
        } else {
            // disconnect from single destination
            connectedDestinations.remove(destination);
            destination.removeActiveSourceNode(this);
        }
    }

    function addActiveSourceNode(node: AudioNode) {
        if (!Lambda.has(activeSources, node)) {
            if (node.nativeNode != null) {
                this.nativeNodeList.add(node.nativeNode);
            }
            activeSources.add(node);
        }
    }

    function removeActiveSourceNode(node: AudioNode) {
        if (node.nativeNode != null) {
            this.nativeNodeList.remove(node.nativeNode);
        }
        activeSources.remove(node);
    }

    /**
        A node is considered active when it can supply input
    **/
    function activate() {
        nativeNode.setActive(true);
        for (destination in connectedDestinations) {
            destination.addActiveSourceNode(this);
            destination.activate();
        }
    }
    
    function tryDeactivate() {
        if (activeSources.length == 0) {
            nativeNode.setActive(false);
            for (destination in connectedDestinations) {
                destination.removeActiveSourceNode(this);
                destination.tryDeactivate();
            }
        }
    }

    function setDecoder(decoder: AudioDecoder) {
        // set the native decoder first so we have to wait on the AudioNode lock
        if (nativeNode != null) {
            this.nativeNode.setDecoder(decoder.nativeAudioDecoder);
        }
        this.decoder = decoder;
    }

    static function finalizer(instance: AudioNode) {
        #if debug
        Stdio.printf("%s\n", "[debug] AudioNode.finalizer()");
        #end
        NativeAudioNode.destroy(instance.nativeNode);
        NativeAudioNodeList.destroy(instance.nativeNodeList);
    }

}

/**
    `transformFunction` is executed on the audio thread, mutex locking must be used is the transform data is changed from the haxe thread
    Additionally, it's critical no haxe-allocation or vm interaction occurs within `transformFunction`.
**/
@:generic class PcmTransformNode<T> extends AudioNode {

    // we pass the address to these fields as function data (not their values)
    final readFramesData: PcmTransformData<T>;

    public function new(context: AudioContext, audioThreadTransformFunction: PcmTransformFunction<T>, transformData: T) {
        super(context);
        
        this.readFramesData = new PcmTransformData(Pointer.fromHandle(this.nativeNodeList), audioThreadTransformFunction, transformData);

        this.nativeNode.setUserData(cast Native.addressOf(this.readFramesData));
        this.nativeNode.setReadFramesCallback(Function.fromStaticFunction(PcmTransform.readFramesCallback));
        this.nativeNode.setActive(true);
    }

}

private typedef PcmTransformFunction<T> = Callable<(data: Star<T>, nChannels: UInt32, frameCount: UInt32, schedulingCurrentFrameBlock: Int64, interleavedPcmSamples: RawPointer<Float32>) -> Void>;

@:access(audio.AudioContext)
private class PcmTransform {
    
    /**
        This is called from the unmanaged audio thread. It's critical that no haxe-allocation or haxe vm interaction occurs here
        @! maybe move this and PcmTransformData to C
    **/
    @:noDebug static public function readFramesCallback<T>(sourceUserData: Star<cpp.Void>, nChannels: UInt32, frameCount: UInt64, schedulingCurrentFrameBlock: Int64, interleavedSamples: Star<Float32>): UInt64 {
        var readFramesData: Star<PcmTransformData<T>> = cast sourceUserData;
        var framesRead = AudioContext.mixSources(readFramesData.nativeNodeList, nChannels, frameCount, schedulingCurrentFrameBlock, interleavedSamples);
        // apply user transform to frames read
        readFramesData.transformFunction(readFramesData.transformDataStar, nChannels, framesRead, schedulingCurrentFrameBlock, cast interleavedSamples);
        return framesRead;
    }

}

@:generic private class PcmTransformData<T> {

    public final nativeNodeList: Star<NativeAudioNodeList>;
    public final transformFunction: PcmTransformFunction<T>;
    public final transformDataStar: Star<T>;
    final transformData: T;

    public function new(
        nativeNodeList: Pointer<NativeAudioNodeList>,
        transformFunction: PcmTransformFunction<T>,
        transformData: T
    ) {
        this.nativeNodeList = nativeNodeList.ptr;
        this.transformFunction = transformFunction;
        this.transformData = transformData;
        this.transformDataStar = cast Native.addressOf(this.transformData); // must be this.transformData
    }

}

#end