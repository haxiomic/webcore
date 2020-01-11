! Main loop does not occur on iOS and Android !
    - It's because there is no `main()` and 
        "If `haxe.MainLoop` is kept from DCE, then we will insert an `haxe.EntryPoint.run()` call just at then end of `main()`.
        This class can be redefined by custom frameworks so they can handle their own main loop logic."
! Ensure initialization thread is the same as drawFrame thread on iOS and Android !
! To solve the connection gc issue, maybe we don't make the connection two-way until start() occurs !
That is
{
    var node = audioContext.createNode();
    node.connect(audioContext.destination) // only store connected destination in node, not in destination
    // node.start(), now a two-way link is created
    node = null;
    // node should get collected if used or not
}

- [ ] iOS event loop
- [ ] Android event loop

- Implement AudioParam and GainNode value
- Review calling finalizers if throw when contructing
- [ ] Fix iOS web
- [ ] AudioSprite play/pause support
- [ ] Move audio to lib

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
- [ ] Can we include the JNI code inside the main codebase so it's not compiled separately with Android?
- [ ] Explicit path resolution in Assets.hx