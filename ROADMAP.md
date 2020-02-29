- [ ] Image via stb_image
    - test image
        - when we reformat from 3 to 4 channels, alpha is set to 0. Is this at a mismatch with the web?
    - .src

- Lock with the audio source when using it in mixSources to prevent use-after-free of the decoder
    - Since it's not locked, the decoder can be changed, and then cleared by the GC (while a reference is held )
- Minimize lock contention by splitting mixSources into time quanta (as specified in the specification)
- AudioNode GC improvement: don't make the connection two-way until start() occurs
That is
{
    var node = audioContext.createNode();
    node.connect(audioContext.destination) // only store connected destination in node, not in destination
    // node.start(), now a two-way link is created
    node = null;
    // node should get collected if used or not
}

- Implement AudioParam and GainNode value

- Generate an .aar for easy Android integration
    https://medium.com/@yushulx/how-to-build-so-library-files-into-aar-bundle-in-android-studio-a44387c9a012

- [ ] Fix iOS web
- [ ] AudioSprite play/pause support

- [ ] Asset system
    - [ ] Platform native code
- [ ] App main + platform native code
    - [ ] View resized
    - [ ] App life cycle
    - [ ] Keyboard events
- [ ] Settings files per system
    - [ ] local storage?
    - [ ] iOS settings
    - [ ] Android settings
    - [ ] Desktop to file? Or Windows/mac settings?
- [ ] Less boilerplate per platform -> code generation
- [ ] Switch to dynamic libraries so we can link with system libraries during haxe compile (and not platform compile)
    - [ ] Link with AVFoundation and AudioToolbox when building lib for iOS and OpenSLES for Android

- Review calling finalizers if throw when contructing


-----

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

- Promises
    - Return promise for Image.decodeImageData and AudioContext.decodeAudioData