package audio;

#if js

typedef GainNode = js.html.audio.GainNode;

#else

import cpp.*;

class GainNode extends AudioNode.PcmTransformNode<AudioParam> {

	/**
		Is an a-rate `AudioParam` representing the amount of gain to apply. You have to set `AudioParam.value` or use the methods of `AudioParam` to change the effect of gain.
	**/
	public var gain(default,null): AudioParam;

	public function new(context: AudioContext,  ?options: {
		var ?gain: Float;
	}) {
		gain = @:privateAccess new AudioParam(context);
		gain.value = options != null && options.gain != null ? options.gain : 1.0;

		super(context, Function.fromStaticFunction(applyGain), gain);
		numberOfInputs = 1;
		numberOfOutputs = 1;
	}

	@:noDebug static function applyGain(gainParamStar: Star<AudioParam>, nChannels: UInt32, frameCount: UInt32, schedulingCurrentFrameBlock: Int64, interleavedPcmSamples: RawPointer<Float32>) {
		var gain: Float = gainParamStar.value;
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