package audio.native;

import audio.native.AudioDecoder.NativeAudioDecoder;
import cpp.*;

@:allow(audio.native.AudioContext)
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
            this.nativeSource.decoder = decoder.nativeAudioDecoder;
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
        this.nativeSource.setPlaying(true);
    }

    public inline function stop() {
        this.nativeSource.setPlaying(false);
    }
}

@:allow(audio.native.AudioContext)
class AudioBufferSourceNode extends AudioScheduledSourceNode {

    public var loop (get, set): Bool;

    public var buffer (get, set): AudioBuffer;
    var _buffer: AudioBuffer;

    inline function get_buffer(): AudioBuffer {
        return this._buffer;
    }

    inline function set_buffer(b: AudioBuffer): AudioBuffer {
        // create a decoder for this buffer
        var bytesDecoder = new AudioDecoder.FileBytesDecoder(context, b.audioFileBytes);
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

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('AudioSource') @:unreflective
@:structAccess
@:access(audio.native.AudioContext)
extern class NativeAudioSource {

    var decoder: Star<NativeAudioDecoder>;
    var lock: Star<MiniAudio.Mutex>;
    private var playing: Bool;
    private var loop: Bool;

    inline function getPlaying(): Bool {
        return lock.locked(() -> playing);
    }

    inline function setPlaying(v: Bool): Bool {
        return lock.locked(() -> playing = v);
    }

    inline function getLoop(): Bool {
        return lock.locked(() -> loop);
    }

    inline function setLoop(v: Bool): Bool {
        return lock.locked(() -> loop = v);
    }

    @:native('~AudioSource')
    function free(): Void;

    @:native('new AudioSource')
    static function alloc(): Star<NativeAudioSource>;

    static inline function create(maContext: Star<MiniAudio.Context>): Star<NativeAudioSource> {
        var instance = alloc();
        instance.lock = MiniAudio.Mutex.alloc();
        instance.lock.init(maContext);
        instance.decoder = null;
        instance.playing = false;
        instance.loop = false;
        return instance;
    }

    static inline function destroy(instance: NativeAudioSource): Void {
        instance.free();
        instance.lock.uninit();
        instance.lock.free();
    }

}

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('AudioSourceList') @:unreflective
@:structAccess
extern class NativeAudioSourceList {

    inline function add(source: Star<NativeAudioSource>): Void {
        untyped __global__.AudioSourceList_add(this, source);
    }

    inline function remove(source: Star<NativeAudioSource>): Bool {
        return untyped __global__.AudioSourceList_remove(this, source);
    }

    @:native('AudioSourceList_create')
    static function create(maContext: Star<MiniAudio.Context>): Star<NativeAudioSourceList>;

    @:native('AudioSourceList_destroy')
    static function destroy(instance: Star<NativeAudioSourceList>): Void;

}