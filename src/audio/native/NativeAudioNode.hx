package audio.native;

import cpp.*;
import audio.native.AudioDecoder;

typedef ReadFramesCallback = Callable<(source: Star<NativeAudioNode>, nChannels: UInt32, frameCount: UInt64, schedulingCurrentFrameBlock: Int64, interleavedSamples: Star<Float32>) -> UInt64>;

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('AudioNode') @:unreflective
@:structAccess
@:access(audio.AudioContext)
extern class NativeAudioNode {

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

    @:native('~AudioNode')
    function free(): Void;

    @:native('new AudioNode')
    static function alloc(): Star<NativeAudioNode>;

    static inline function create(maContext: Star<audio.native.MiniAudio.Context>): Star<NativeAudioNode> {
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

    static inline function destroy(instance: NativeAudioNode): Void {
        instance.free();
        instance.lock.uninit();
        instance.lock.free();
    }

}

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('AudioNodeList') @:unreflective
@:structAccess
extern class NativeAudioNodeList {

    inline function add(source: Star<NativeAudioNode>): Void {
        untyped __global__.AudioNodeList_add(this, source);
    }

    inline function remove(source: Star<NativeAudioNode>): Bool {
        return untyped __global__.AudioNodeList_remove(this, source);
    }

    @:native('AudioNodeList_create')
    static function create(maContext: Star<audio.native.MiniAudio.Context>): Star<NativeAudioNodeList>;

    @:native('AudioNodeList_destroy')
    static function destroy(instance: Star<NativeAudioNodeList>): Void;

}