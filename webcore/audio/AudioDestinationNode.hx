package webcore.audio;

#if js

typedef AudioDestinationNode  = js.html.audio.AudioDestinationNode ;

#else

import webcore.audio.native.AudioDecoder;

@:allow(webcore.audio.AudioContext)
class AudioDestinationNode extends AudioNode {

	function new(context: AudioContext, ?decoder: AudioDecoder) {
		super(context, decoder);
		numberOfInputs = 1;
		numberOfOutputs = 1;
	}

}

#end