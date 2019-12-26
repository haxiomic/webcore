package audio.native;

import cpp.*;

@:allow(audio.native.AudioContext)
class AudioSource {

    var nativeSource: Star<ExternAudioSource>;

}

@:include('./native.h')
@:sourceFile('./native.c')
@:native('AudioSourceList') @:unreflective
@:structAccess
extern class ExternAudioSource {}