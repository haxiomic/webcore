- AudioNode GC improvement: don't make the connection two-way until start() occurs
That is
{
    var node = audioContext.createNode();
    node.connect(audioContext.destination) // only store connected destination in node, not in destination
    // node.start(), now a two-way link is created
    node = null;
    // node should get collected if used or not
}
    -> Need to iterate through node tree activating nodes

- Implement AudioParam and GainNode value

- Generate an .aar for easy Android integration
    https://medium.com/@yushulx/how-to-build-so-library-files-into-aar-bundle-in-android-studio-a44387c9a012

- [ ] Fix iOS web

- [ ] App main + platform native code
    - [ ] View resized
    - [ ] App life cycle
    - [ ] Keyboard events
- [ ] Asset system
    - [ ] Platform native code
- [ ] Settings files per system
    - [ ] local storage?
    - [ ] iOS settings
    - [ ] Android settings
    - [ ] Desktop to file? Or Windows/mac settings?
- [ ] Switch to dynamic libraries so we can link with system libraries during haxe compile (and not platform compile). Or add metadata to add flags to platform projects
    - [ ] Link with AVFoundation and AudioToolbox when building lib for iOS and OpenSLES for Android

- [ ] New desktop demo

- Review calling finalizers if throw when contructing


-----

# Auditing

- Why is tsan reporting two different mutexes for the same lock?
    - ma_mutex_lock(&source->lock) 
    - and this.nativeNode.setDecoder(decoder.nativeAudioDecoder);

-> Maybe, avoid using hxcpp threads; crash risk:
    - Make async method `readAllPcmFramesAsync()`
    - These methods should spawn a miniaudio thread and execute a haxe callback
        -> How do we call successCallback when complete
            -> poll a flag (short-term fix)
            -> write to a linked list of callbacks and wake up the main event loop lock
                -> Probably requires overriding EntryPoint 
        - `AudioDecoder_readPcmFramesAsync(AudioDecoder* decoder, ma_uint64 frameCount, void* pFramesOut, callback onComplete, void* callbackData)`

    ===> Did thread stress-test without issue so not sure if this is critical

-----

# Future

- Promises
    - Return promise for Image.decodeImageData and AudioContext.decodeAudioData

- WebGL
    - Implement extensions
    - Enable support for flipY and premultiply alpha

- Image.src
    - Loading images from `src` requires supporting event listeners so you can catch load complete

- Haxe's MainLoop doesn't appear thread safe X_X
    - Also we should sort _while inserting_ 
    - We should probably redefine so it wakes the event loop when a new event is added

- Maybe rename HaxeApp -> HaxeAppView or similar
