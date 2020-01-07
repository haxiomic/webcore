package audio;

#if js

typedef AudioBuffer = js.html.audio.AudioBuffer;

#else

/**
    Represents raw PCM frames
    Internally this is stored as interleaved samples for each channel
**/
@:allow(audio.AudioContext)
@:allow(audio.AudioBufferSourceNode)
class AudioBuffer {
    
    // could use ma_deinterleave_pcm_frames to get separate buffers
    final interleavedPcmBytes: haxe.io.Bytes;

    function new(interleavedPcmBytes: haxe.io.Bytes) {
        this.interleavedPcmBytes = interleavedPcmBytes;
    }

}

#end