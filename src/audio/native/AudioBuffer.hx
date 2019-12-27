package audio.native;

@:allow(audio.native.AudioContext)
@:allow(audio.native.AudioBufferSourceNode)
class AudioBuffer {

    final audioFileBytes: haxe.io.Bytes;

    function new(audioFileBytes: haxe.io.Bytes) {
        this.audioFileBytes = audioFileBytes;
    }

}