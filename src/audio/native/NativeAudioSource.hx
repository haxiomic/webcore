package audio.native;

import cpp.*;
import audio.native.AudioDecoder;

typedef ReadFramesCallback = Callable<(source: Star<NativeAudioSource>, nChannels: UInt32, frameCount: UInt64, schedulingCurrentFrameBlock: Int64, interleavedSamples: Star<Float32>) -> UInt64>;

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('AudioSource') @:unreflective
@:structAccess
@:access(audio.AudioContext)
extern class NativeAudioSource {

    var lock: Star<audio.native.MiniAudio.Mutex>;
    private var readFramesCallback: ReadFramesCallback;
    private var decoder: Star<NativeAudioDecoder>;
    private var active: Bool;
    private var loop: Bool;
    private var onReachEofFlag: Bool;
    private var userData: Star<cpp.Void>;

    inline function setReadFramesCallback(callback: ReadFramesCallback): ReadFramesCallback {
        return lock.locked(() -> readFramesCallback = callback);
    }

    inline function getReadFramesCallback(): ReadFramesCallback {
        return lock.locked(() -> readFramesCallback);
    }

    inline function setDecoder(newDecoder: Star<NativeAudioDecoder>): Star<NativeAudioDecoder> {
        return lock.locked(() -> decoder = newDecoder);
    }

    inline function getDecoder(): Star<NativeAudioDecoder> {
        return lock.locked(() -> decoder);
    }

    inline function getActive(): Bool {
        return lock.locked(() -> active);
    }

    inline function setActive(v: Bool): Bool {
        return lock.locked(() -> active = v);
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

    inline function setUserData(newUserData: Star<cpp.Void>): Star<cpp.Void> {
        return lock.locked(() -> userData = newUserData);
    }

    inline function getUserData(): Star<cpp.Void> {
        return lock.locked(() -> userData);
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
        instance.readFramesCallback = null;
        instance.active = false;
        instance.loop = false;
        instance.onReachEofFlag = false;
        instance.userData = null;
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