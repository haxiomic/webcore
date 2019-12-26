package audio.native;

import audio.native.AudioSource.ExternAudioSource;
import cpp.*;

@:allow(audio.native.AudioContext)
class AudioNode {

    public final context: AudioContext;
    var source: Null<AudioSource>;

    final nativeSourceList: Star<ExternAudioSourceList>;
    final connectedSources = new List<AudioNode>();
    final connectedDestinations = new List<AudioNode>();

    function new(context: AudioContext, ?source: AudioSource) {
        this.context = context;
        this.source = source;
        nativeSourceList = ExternAudioSourceList.create(context.maDevice.pContext);

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

    function updateSource(newSource: Null<AudioSource>) {
        // first disconnect all existing destinations
        var connectedDestinationsCopy = new List<AudioNode>();
        for (node in connectedDestinations) {
            connectedDestinationsCopy.add(node);
        }

        for (node in connectedDestinationsCopy) {
            disconnect(node);
        }

        // change value of source
        this.source = newSource;

        // reconnect
        for (node in connectedDestinationsCopy) {
            connect(node);
        }
    }

    function addSourceNode(node: AudioNode) {
        if (!Lambda.has(connectedSources, node)) {
            connectedSources.add(node);
            if (node.source != null) {
                this.nativeSourceList.add(node.source.nativeSource);
            }
        }
    }

    function removeSourceNode(node: AudioNode) {
        connectedSources.remove(node);
        if (node.source != null) {
            this.nativeSourceList.remove(node.source.nativeSource);
        }
    }

    static function finalizer(instance: AudioNode) {
        #if debug
        Stdio.printf("%s\n", "[debug] AudioNode.finalizer()");
        #end
        ExternAudioSourceList.destroy(instance.nativeSourceList);
    }

}

class AudioBufferSourceNode extends AudioScheduledSourceNode {

    public var buffer (get, set): AudioBuffer;

    inline function get_buffer(): AudioBuffer {
        return cast this.source;
    }

    inline function set_buffer(b: AudioBuffer): AudioBuffer {
        updateSource(b);
        return b;
    }

}

class AudioScheduledSourceNode extends AudioNode {
    // public function start()
    // public function stop()
}

@:include('./native.h')
@:sourceFile('./native.c')
@:native('AudioSourceList') @:unreflective
@:structAccess
extern class ExternAudioSourceList {

    inline function add(source: Star<ExternAudioSource>): Void {
        untyped __global__.AudioSourceList_add(this, source);
    }

    inline function remove(source: Star<ExternAudioSource>): Bool {
        return untyped __global__.AudioSourceList_remove(this, source);
    }

    @:native('AudioSourceList_create')
    static function create(context: Star<MiniAudio.Context>): Star<ExternAudioSourceList>;

    @:native('AudioSourceList_destroy')
    static function destroy(instance: Star<ExternAudioSourceList>): Void;

}