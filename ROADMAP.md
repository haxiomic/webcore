- [ ] Decide Assets path resolution rules

- [ ] createBuffer( numberOfChannels : Int, length : Int, sampleRate : Float ) : AudioBuffer;
- [ ] volume
    - GainNode –> Custom decoder, store nativeAudioSources in userData, call mixSources in onRead and then apply transform
- [ ] end-of-source handling
    - onEnd callback
    - flag that's ready in a haxe main loop
- [ ] WebAudio timing system (currentTime and start(t, offset))

- [ ] Fix iOS web
- [ ] Switch to dynamic libraries so we can link with system libraries during haxe compile (and not platform compile)
    - [ ] Link with AVFoundation and AudioToolbox when building lib for iOS and OpenSLES for Android
- [ ] Can we include the JNI code inside the main codebase so it's not compiled separately with Android?
- [ ] Explicit path resolution in Assets.hx