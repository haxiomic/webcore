package audio;

#if js

typedef AudioScheduledSourceNode = js.html.audio.AudioScheduledSourceNode;

#else

@:allow(audio.native.AudioContext)
class AudioScheduledSourceNode extends AudioNode {

    /**
        @throws String
    **/
    public function start(when: Float = 0.0, offset: Float = 0.0, ?duration: Float) {
        if (nativeNode.getScheduledStartFrame() != -1) {
            throw "Failed to execute 'start' on 'AudioBufferSourceNode': cannot call start more than once.";
        }

        nativeNode.setActive(true);
        nativeNode.setScheduledStartFrame(cast context.sampleRate * when);

        if (offset != 0.0 && decoder != null) {
            decoder.seekToPcmFrame(cast decoder.sampleRate * offset);
        }

        if (duration != null) {
            stop(when + duration);
        }
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

}

#end