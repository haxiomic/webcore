package audio;

#if js

typedef AudioScheduledSourceNode = js.html.audio.AudioScheduledSourceNode;

#else

@:allow(audio.native.AudioContext)
class AudioScheduledSourceNode extends AudioNode {

    public inline function start() {
        this.nativeSource.setActive(true);
    }

    public inline function stop() {
        this.nativeSource.setActive(false);
    }

}

#end