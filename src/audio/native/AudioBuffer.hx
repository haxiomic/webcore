package audio.native;

/**
    Rather than storing raw PCM frames, we store the original audio file bytes and then decode as required
    It would be better to store raw PCM frames, however this requires locking the decoder while reading
**/
@:allow(audio.native.AudioContext)
@:allow(audio.native.AudioBufferSourceNode)
class AudioBuffer {

    final audioFileBytes: haxe.io.Bytes;

    function new(audioFileBytes: haxe.io.Bytes) {
        this.audioFileBytes = audioFileBytes;
    }

}