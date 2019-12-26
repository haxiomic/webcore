package audio;

#if js

typedef AudioNode = js.html.audio.AudioNode;
typedef AudioBufferSourceOptions = js.html.audio.AudioBufferSourceOptions;
typedef AudioBufferSourceNode = js.html.audio.AudioBufferSourceNode;
typedef AudioDestinationNode = js.html.audio.AudioDestinationNode;

#else

class AudioNode {
	/**
		Allows us to connect the output of this node to be input into another node, either as audio data or as the value of an `AudioParam`.
	**/
	function connect(destination:AudioNode): Void;

	function disconnect(?destination: AudioNode): Void;

}

typedef AudioBufferSourceOptions = {
	var ?buffer : AudioBuffer;
	var ?detune : Float;
	var ?loop : Bool;
	var ?loopEnd : Float;
	var ?loopStart : Float;
	var ?playbackRate : Float;
}

class AudioBufferSourceNode {

	/**
		A function to be called when the `ended` event is fired, indicating that the node has finished playing.
	**/
	public var onended: haxe.Constraints.Function;
	/**
		An `AudioBuffer` that defines the audio asset to be played, or when set to the value `null`, defines a single channel of silence (in which every sample is 0.0).
	**/
	public var buffer: AudioBuffer;	
	/**
		A Boolean attribute indicating if the audio asset must be replayed when the end of the `AudioBuffer` is reached. Its default value is `false`.
	**/
	public var loop: Bool;

	public function new(context: AudioContext.BaseAudioContext, ?options: AudioBufferSourceOptions) {
		// @! todo
		throw 'todo';
	}

	public function start(when: Float = 0.0, grainOffset: Float = 0.0, ?grainDuration: Float): Void {
		throw 'todo start';
	}

	public function stop(when: Float = 0.0): Void {
		throw 'todo stop';
	}

}

class AudioDestinationNode extends AudioNode {
}

#end