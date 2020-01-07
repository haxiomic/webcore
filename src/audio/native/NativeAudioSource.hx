package audio.native;

import cpp.*;
import audio.native.AudioDecoder;

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('AudioSource') @:unreflective
@:structAccess
@:access(audio.AudioContext)
extern class NativeAudioSource {

    var decoder: Star<NativeAudioDecoder>;
    var lock: Star<audio.native.MiniAudio.Mutex>;
    private var playing: Bool;
    private var loop: Bool;
    private var onReachEofFlag: Bool;

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

    inline function getOnReachEofFlag(): Bool {
        return lock.locked(() -> onReachEofFlag);
    }

    inline function setOnReachEofFlag(v: Bool): Bool {
        return lock.locked(() -> onReachEofFlag = v);
    }

    @:native('~AudioSource')
    function free(): Void;

    @:native('new AudioSource')
    static function alloc(): Star<NativeAudioSource>;

    static inline function create(maContext: Star<audio.native.MiniAudio.Context>): Star<NativeAudioSource> {
        var instance = alloc();
        instance.lock = audio.native.MiniAudio.Mutex.alloc();
        instance.lock.init(maContext);
        instance.decoder = null;
        instance.playing = false;
        instance.loop = false;
        instance.onReachEofFlag = false;
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
    static function create(maContext: Star<audio.native.MiniAudio.Context>): Star<NativeAudioSourceList>;

    @:native('AudioSourceList_destroy')
    static function destroy(instance: Star<NativeAudioSourceList>): Void;

}