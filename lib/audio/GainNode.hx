package audio;

#if js

typedef GainNode = js.html.audio.GainNode;

#else

import cpp.*;

class GainNode extends AudioNode.PcmTransformNode<Float> {

    public function new(context: AudioContext,  ?options: {
        var ?gain: Float;
    }) {
        var gainValue = options != null && options.gain != null ? options.gain : 1.0;
        super(context, Function.fromStaticFunction(applyGain), gainValue);
    }

    @:noDebug static function applyGain(gainStar: Star<Float>, nChannels: UInt32, frameCount: UInt32, schedulingCurrentFrameBlock: Int64, interleavedPcmSamples: RawPointer<Float32>) {
        var gain: Float = Native.star(gainStar);
        if (gain == 1.0) return;
        if (gain == 0.0) {
            untyped __cpp__('memset({0}, 0, {1})', interleavedPcmSamples, frameCount * nChannels);
            return;
        }
        // we use inline C++ here because a for-loop will vectorize better than hxcpp's while-loop
        untyped __cpp__('
            int totalSamples = frameCount*nChannels;
            for (int i = 0; i < totalSamples; i++) {
                {0}[i] *= {1};
            }
        ', interleavedPcmSamples, gain);
    }

}

#end