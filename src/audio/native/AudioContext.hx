package audio.native;

import audio.native.AudioSource.FileAudioSource;
import audio.native.AudioSource.ExternAudioSource;
import cpp.*;
using Lambda;

@:include('./native.h')
@:sourceFile('./native.c')
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

    static var gcReference = new List<AudioContext>();

    static function finalizer(instance: AudioContext) {
        #if debug
        Stdio.printf("%s\n", "[debug] AudioContext.finalizer()");
        #end

        instance.maDevice.uninit();
        instance.maDevice.free();
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