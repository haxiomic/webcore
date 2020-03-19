package audio;

#if js

typedef AudioBufferSourceNode = js.html.audio.AudioBufferSourceNode;

#else

import audio.native.AudioDecoder;

@:allow(audio.AudioContext)
class AudioBufferSourceNode extends AudioScheduledSourceNode {

	function new(context: AudioContext, ?decoder: AudioDecoder) {
		super(context, decoder);
		numberOfInputs = 0;
		numberOfOutputs = 1;
	}

	public var loop (get, set): Bool;

	public var buffer (get, set): AudioBuffer;
	var _buffer: AudioBuffer;

	inline function get_buffer(): AudioBuffer {
		return this._buffer;
	}

	inline function set_buffer(b: AudioBuffer): AudioBuffer {
		// create a decoder for this buffer
		var bytesDecoder = new PcmBufferDecoder(context, b.interleavedPcmBytes, {
			channels: b.config.channels,
			sampleRate: b.config.sampleRate
		});
		setDecoder(bytesDecoder);
		return _buffer = b;
	}

	inline function get_loop(): Bool {
		return this.nativeNode.getLoop();
	}

	inline function set_loop(v: Bool): Bool {
		return this.nativeNode.setLoop(v);
	}

}

#end