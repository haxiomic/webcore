package audio.native;

import audio.native.AudioSource.ExternAudioSource;
import cpp.*;
using Lambda;

@:include('./native.h')
@:sourceFile('./native.c')
class AudioContext {

    final maDevice: Star<MiniAudio.Device>;
    final nativeSourceList: Star<ExternAudioSourceList>;
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

        nativeSourceList = ExternAudioSourceList.create(maDevice.pContext);
        maDevice.pUserData = cast nativeSourceList;

        cpp.vm.Gc.setFinalizer(this, Function.fromStaticFunction(finalizer));

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

    public inline function addSource(source: AudioSource) {
        if (!activeSources.has(source)) {
            activeSources.add(source);
            this.nativeSourceList.add(source.nativeSource);
        }
    }

    public inline function removeSource(source: AudioSource) {
        activeSources.remove(source);
        this.nativeSourceList.remove(source.nativeSource);
    }

    static var gcReference = new List<AudioContext>();

    static function finalizer(instance: AudioContext) {
        Stdio.printf("%s", "AudioContext.finalizer\n");

        instance.maDevice.uninit();
        instance.maDevice.free();
        ExternAudioSourceList.destroy(instance.nativeSourceList);
    }

}

@:include('./native.h')
@:sourceFile('./native.c')
@:native('AudioSourceList') @:unreflective
@:structAccess
extern class ExternAudioSourceList {

    inline function add(source: Star<ExternAudioSource>): Void {
        untyped __global__.AudioSource_add(this, source);
    }

    inline function remove(source: Star<ExternAudioSource>): Bool {
        return untyped __global__.AudioSource_remove(this, source);
    }

    @:native('AudioSourceList_create')
    static function create(context: Star<MiniAudio.Context>): Star<ExternAudioSourceList>;

    @:native('AudioSourceList_destroy')
    static function destroy(instance: Star<ExternAudioSourceList>): Void;

}