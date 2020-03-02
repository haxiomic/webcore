package audio;

#if js

typedef AudioScheduledSourceNode = js.html.audio.AudioScheduledSourceNode;

#else

import audio.native.AudioDecoder;

@:allow(audio.native.AudioContext)
class AudioScheduledSourceNode extends AudioNode {

    public var onended: Null<haxe.Constraints.Function>;

    function new(context: AudioContext, ?decoder: AudioDecoder) {
        super(context, decoder);
        numberOfInputs = 0;
        numberOfOutputs = 1;
    }

    /**
        @throws String
    **/
    public function start(when: Float = 0.0, offset: Float = 0.0, ?duration: Float) {
        if (nativeNode.getScheduledStartFrame() != -1) {
            throw "Failed to execute 'start' on 'AudioBufferSourceNode': cannot call start more than once.";
        }

        activate();
        nativeNode.setScheduledStartFrame(cast context.sampleRate * when);

        if (offset != 0.0 && decoder != null) {
            decoder.seekToPcmFrame(cast decoder.sampleRate * offset);
        }

        if (duration != null) {
            stop(when + duration);
        }

        // while running, we poll onReachEndFlag to trigger the onend event
        pollReachedEndFlag();
    }

    /**
        @throws String
    **/
    public function stop(when: Float = 0.0) {
        if (nativeNode.getScheduledStartFrame() == -1) {
            throw "Failed to execute 'stop' on 'AudioScheduledSourceNode': cannot call stop without calling start first";
        }
        nativeNode.setScheduledStopFrame(cast context.sampleRate * when);
    }

    function handledReachedEnd() {
        // disconnect from all down-stream nodes
        // @! this changes the connected node count (which doesn't change on browser WebAudio), however the node _is_ disconnected in browser WebAudio
        // see https://bugs.chromium.org/p/chromium/issues/detail?id=452966
        this.tryDeactivate();

        if (onended != null) {
            onended();
        }
    }

    function pollReachedEndFlag() {
        if (nativeNode.getOnReachEndFlag()) {
            handledReachedEnd();
        } else {
            // keep polling until end
            haxe.Timer.delay(pollReachedEndFlag, 1);
        }
    }

}

#end