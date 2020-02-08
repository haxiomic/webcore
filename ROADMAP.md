- Use arch folders rather than simulator and device
- Modify haxe args so we rebuild for the current Xcode arch

- Generate an .aar for easy Android integration
    https://medium.com/@yushulx/how-to-build-so-library-files-into-aar-bundle-in-android-studio-a44387c9a012

- Lock with the audio source when using it in mixSources to prevent use-after-free of the decoder

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
- Review calling finalizers if throw when contructing

- [ ] Fix iOS web
- [ ] AudioSprite play/pause support

- [ ] Image via stb_image
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