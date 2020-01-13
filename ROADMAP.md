- C interface for App 
- https://stackoverflow.com/questions/15496862/delay-a-method-call-in-objective-c/15496921

- Can we generate a .framework for iOS?
    https://theswiftdev.com/2018/01/25/deep-dive-into-swift-frameworks/
- And generate an .aar for Android?
    https://medium.com/@yushulx/how-to-build-so-library-files-into-aar-bundle-in-android-studio-a44387c9a012

    => The bundling code should be independent from the AppInterface (so you can make non-graphics bundles)
    => Maybe a macro generates a bash/bat script in the hxcpp output directory that creates the frameworks when executed
    => Users then do `-cmd _hxcpp-bin/generate-lib.sh`

    => A compiler macro could be used to make this easy, so adding something like
        `--macro Tool.generateIOSFramework('com.example.MyFrameworkName')`
        This might also add `-D HAXE_OUTPUT_PART=MinimalGL` and
            ```
            --each
            -D iphoneos
            -D HXCPP_ARM64
            --next
            -D iphonesim
            -D HXCPP_M64
            ```
        Ideally this generate the native platform glue code – C-API and Swift/Java/JNI

- [ ] Switch to dynamic libraries so we can link with system libraries during haxe compile (and not platform compile)
    - [ ] Link with AVFoundation and AudioToolbox when building lib for iOS and OpenSLES for Android

- Move gluon to HaxeNativeWeb.webgl
- Move audio to HaxeNativeWeb.webaudio
- Maybe move asset too?

- [ ] iOS event loop via GCD `dispatch_after`
- [ ] Android event loop


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