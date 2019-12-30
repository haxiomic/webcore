package audio.native;

/**
    Represents raw PCM frames
    Internally this is stored as interleaved samples for each channel, however WebAudio uses separate buffers per channel
**/
@:allow(audio.native.AudioContext)
@:allow(audio.native.AudioBufferSourceNode)
class AudioBuffer {
    
    // could use ma_deinterleave_pcm_frames to get separate buffers
    final interleavedPcmBytes: haxe.io.Bytes;

    function new(interleavedPcmBytes: haxe.io.Bytes) {
        this.interleavedPcmBytes = interleavedPcmBytes;
    }

}