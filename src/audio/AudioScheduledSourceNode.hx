package audio;

#if js

typedef AudioScheduledSourceNode = js.html.audio.AudioScheduledSourceNode;

#else

@:allow(audio.native.AudioContext)
class AudioScheduledSourceNode extends AudioNode {

    public inline function start() {
        this.nativeNode.setActive(true);
    }

    public inline function stop() {
        this.nativeNode.setActive(false);
    }

}

#end