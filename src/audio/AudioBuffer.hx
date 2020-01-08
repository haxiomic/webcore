package audio;

#if js

typedef AudioBuffer = js.html.audio.AudioBuffer;

#else
import cpp.*;
import audio.native.MiniAudio;

/**
    Represents raw PCM frames
    Internally this is stored as interleaved samples for each channel
**/
@:allow(audio.AudioContext)
@:allow(audio.AudioBufferSourceNode)
class AudioBuffer {
    
    // could use ma_deinterleave_pcm_frames to get separate buffers
    final interleavedPcmBytes: haxe.io.Bytes;
    final config: DecoderConfig;

    function new(interleavedPcmBytes: haxe.io.Bytes, interleavedPcmBytesConfig: {
        final channels: UInt32;
        final sampleRate: UInt32;
    }) {
        this.interleavedPcmBytes = interleavedPcmBytes;
        this.config  = DecoderConfig.init(
            F32,
            interleavedPcmBytesConfig.channels,
            interleavedPcmBytesConfig.sampleRate
        );
    }

}

#end