package audio;

#if js

typedef AudioScheduledSourceNode = js.html.audio.AudioScheduledSourceNode;

#else

@:allow(audio.native.AudioContext)
class AudioScheduledSourceNode extends AudioNode {

    public function start(when: Float = 0.0) {
        this.nativeNode.setActive(true);
        this.nativeNode.setScheduledStartFrame(cast this.context.sampleRate * when);
    }

    public function stop(when: Float = 0.0) {
        this.nativeNode.setScheduledStopFrame(cast this.context.sampleRate * when);
    }

}

#end