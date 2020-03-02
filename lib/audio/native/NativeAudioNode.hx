package audio.native;

import cpp.*;
import audio.native.AudioDecoder;

typedef ReadFramesCallback = Callable<(sourceUserData: Star<cpp.Void>, nChannels: UInt32, frameCount: UInt64, schedulingCurrentFrameBlock: Int64, interleavedSamples: Star<Float32>) -> UInt64>;

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
    private var scheduledStartFrame: Int64;
    private var scheduledStopFrame: Int64;
    private var loop: Bool;
    private var onReachEndFlag: Bool;
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

    inline function getScheduledStartFrame(): Int64 {
        return lock.locked(() -> scheduledStartFrame);
    }

    inline function setScheduledStartFrame(v: Int64): Int64 {
        return lock.locked(() -> scheduledStartFrame = v);
    }

    inline function getScheduledStopFrame(): Int64 {
        return lock.locked(() -> scheduledStopFrame);
    }

    inline function setScheduledStopFrame(v: Int64): Int64 {
        return lock.locked(() -> scheduledStopFrame = v);
    }

    inline function getLoop(): Bool {
        return lock.locked(() -> loop);
    }

    inline function setLoop(v: Bool): Bool {
        return lock.locked(() -> loop = v);
    }

    inline function getOnReachEndFlag(): Bool {
        return lock.locked(() -> onReachEndFlag);
    }

    inline function setOnReachEndFlag(v: Bool): Bool {
        return lock.locked(() -> onReachEndFlag = v);
    }

    inline function setUserData(newUserData: Star<cpp.Void>): Star<cpp.Void> {
        return lock.locked(() -> userData = newUserData);
    }

    inline function getUserData(): Star<cpp.Void> {
        return lock.locked(() -> userData);
    }

    @:native('AudioNode_create')
    static function create(maContext: Star<audio.native.MiniAudio.Context>): Star<NativeAudioNode>;

    @:native('AudioNode_destroy')
    static function destroy(instance: Star<NativeAudioNode>): Void;

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