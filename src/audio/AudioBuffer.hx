package audio;

#if js

typedef AudioBufferOptions = js.html.audio.AudioBufferOptions;
typedef AudioBuffer = js.html.audio.AudioBuffer;

#else

typedef AudioBufferOptions = {
	var length : Int;
	var ?numberOfChannels : Int;
	var sampleRate : Float;
}

class AudioBuffer {
	
	/**
		Returns a float representing the sample rate, in samples per second, of the PCM data stored in the buffer.
	**/
	// final sampleRate: Float;
	
	/**
		Returns an integer representing the length, in sample-frames, of the PCM data stored in the buffer.
	**/
	// final length: Int;
	
	/**
		Returns a double representing the duration, in seconds, of the PCM data stored in the buffer.
	**/
	// final duration: Float;
	
	/**
		Returns an integer representing the number of discrete audio channels described by the PCM data stored in the buffer.
	**/
	// final numberOfChannels: Int;
	
	/** @throws DOMError */
	// function new( options : AudioBufferOptions ) : Void { }
	
	/**
		Returns a `Float32Array` containing the PCM data associated with the channel, defined by the `channel` parameter (with `0` representing the first channel).
		@throws DOMError
	**/
	// function getChannelData( channel : Int ) : typedarray.Float32Array {}
	
	/**
		Copies the samples from the specified channel of the `AudioBuffer` to the `destination` array.
		@throws DOMError
	**/
	// function copyFromChannel( destination : typedarray.Float32Array, channelNumber : Int, startInChannel : Int = 0 ) : Void;
	
	/**
		Copies the samples to the specified channel of the `AudioBuffer`, from the `source` array.
		@throws DOMError
	**/
	// function copyToChannel( source : typedarray.Float32Array, channelNumber : Int, startInChannel : Int = 0 ) : Void;
}

#end