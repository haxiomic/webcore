package audio;

import audio.AudioNode;
#if cpp
import audio.native.AudioDecoder;
#end

/**
    Audio sprite to enable playback of audio files, specified either by their file path or as bytes
**/
/*
@:access(audio.AudioNode)
class AudioSprite {

    public final context: AudioContext;
    public final sourceNode: AudioNode;
    public final isAudioBufferNode: Bool;
    public var playing (get, null): Bool;
    public var loop (get, set): Bool;
    #if js
    public var mediaElement: Null<js.html.AudioElement>;
    #end
    
    var _playing: Bool = false;

    public function new(?context: AudioContext, ?path: String, ?audioFileBytes: haxe.io.Bytes) {
        if (context == null) {
            context = getDefaultAudioContext();
        }

        this.context = context;


        if (path != null) {
            #if js

            // alternatively we could download the full bytes and decode but using a media element enables streaming
            mediaElement = js.Browser.document.createAudioElement();
            mediaElement.src = path;
            sourceNode = context.createMediaElementSource(mediaElement);
            isAudioBufferNode = false;

            #else

            sourceNode = context.createBufferSource();
            var fileDecoder = new FileDecoder(context, path);
            sourceNode.setDecoder(fileDecoder);
            isAudioBufferNode = true;

            #end
        } else if (audioFileBytes != null) {
            var bufferSourceNode: AudioBufferSourceNode;
            sourceNode = bufferSourceNode = context.createBufferSource();
            isAudioBufferNode = true;

            #if js

            context.decodeAudioData(audioFileBytes.getData(), audioBuffer -> bufferSourceNode.buffer = audioBuffer);

            #else

            var fileBytesDecoder = new FileBytesDecoder(context, audioFileBytes, true);
            sourceNode.setDecoder(fileBytesDecoder);
            
            #end

        } else {
            throw 'A path or bytes are required to create an AudioSprite';
        }

        sourceNode.connect(context.destination);
    }

    public function play() {
        // always try to resume the context because play() on a media element does not do this implicitly
        if (context.state == SUSPENDED) {
            context.resume();
        }

        if (_playing) return;
        if (isAudioBufferNode) {
            (cast sourceNode: AudioBufferSourceNode).start();
        } else {
            #if js
            mediaElement.play();
            #end
        }
        _playing = true;
    }

    public function pause() {
        if (!_playing) return;
        if (isAudioBufferNode) {
            (cast sourceNode: AudioBufferSourceNode).stop();
        } else {
            #if js
            mediaElement.pause();
            #end
        }
        _playing = false;
    }

    inline function get_playing() {
        return _playing;
    }

    function get_loop() {
        if (isAudioBufferNode) {
            return (cast sourceNode: AudioBufferSourceNode).loop;
        } else {
            #if js
            return mediaElement.loop;
            #end
        }
        return false;
    }

    function set_loop(v: Bool) {
        if (isAudioBufferNode) {
            return (cast sourceNode: AudioBufferSourceNode).loop = v;
        } else {
            #if js
            return mediaElement.loop = v;
            #end
        }
        return false;
    }

    static var globalContext: Null<AudioContext>;
    static function getDefaultAudioContext() {
        if (globalContext == null) {
            globalContext = new AudioContext();
        }
        return globalContext;
    }

}
*/