package audio;

#if js

typedef AudioParam = js.html.audio.AudioParam;

#else

import audio.native.LockedValue;

/**
    Basic thread-safe AudioParam
    Scheduling not yet implemented

    dev nodes
    - internally we want a method like getValueAtTime(time)
**/
class AudioParam {

    public var value (get, set): Float;

    var _value: LockedValue<Float>;

    function new(context: AudioContext) {
        _value = new LockedValue(context);
    }
    
    inline function get_value() {
        return _value.get();
    }

    inline function set_value(v: Float) {
        return _value.set(v);
    }

}

#end