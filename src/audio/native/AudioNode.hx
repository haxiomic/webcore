package audio.native;

import audio.native.AudioSource.ExternAudioSource;
import cpp.*;

@:allow(audio.native.AudioContext)
class AudioNode {

    public final context: AudioContext;
    final source: Null<AudioSource>;

    final nativeSourceList: Star<ExternAudioSourceList>;
    final activeSources = new List<AudioNode>();

    function new(context: AudioContext, ?source: AudioSource) {
        this.context = context;
        this.source = source;
        nativeSourceList = ExternAudioSourceList.create(context.maDevice.pContext);

        cpp.vm.Gc.setFinalizer(this, Function.fromStaticFunction(finalizer));
    }

    public function connect(destination: AudioNode) {
        destination.addSourceNode(this);
    }

    public function disconnect(destination: AudioNode) {
        destination.removeSourceNode(this);
    }

    function addSourceNode(node: AudioNode) {
        if (node.source == null) return; // node has source

        if (!Lambda.has(activeSources, node)) {
            activeSources.add(node);
            this.nativeSourceList.add(node.source.nativeSource);
        }
    }

    function removeSourceNode(node: AudioNode) {
        if (node.source == null) return; // node has source

        activeSources.remove(node);
        this.nativeSourceList.remove(node.source.nativeSource);
    }

    static function finalizer(instance: AudioNode) {
        #if debug
        Stdio.printf("%s\n", "[debug] AudioNode.finalizer()");
        #end
        ExternAudioSourceList.destroy(instance.nativeSourceList);
    }

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