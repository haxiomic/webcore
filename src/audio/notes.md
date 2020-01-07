TODO:
- volume
    - GainNode –> Custom decoder, store nativeAudioSources in userData, call mixSources in onRead and then apply transform
- end-of-source handling
    - onEnd callback
    - flag that's ready in a haxe main loop
- Link with AVFoundation and AudioToolbox when building lib for iOS
    - Why doesn't this work? Not able to see correct SDK frameworks?