Remapping
- typedarray.* -> wc.*
- image.* -> wc.Image
- audio.* -> wc.audio.*
- device.* -> wc.Device
- filesystem.* -> wc.FileSystem

**! Event issue:**
Pointer up x is probably relative to window coordinates, not canvas (same for other events)

---

- wc.View is a UI view that has the standard event interface (pointer, keyboard, resize and activate)
    - Views cannot be added as children of other views
    - Uses autoBuild to expose the view
    - Has width and height (which are set externally?)
- wc.WebGLView extends WCView
    - Is a WCView backed by a graphics context
- wc.GpuView

- Users extend one or more of these views
- When intergrating into the native platform users do
    nativeView = WebCore.createView(className);
    -> This is a native view type that can be added to the native ui tree

- wc.ui.Input -> native input UI`


-----------

- Rename: App -> View, View/Window is the right abstraction, rather than 'App'
- HaxeAppInterface -> Should be HaxeViewInterface or HaxeAppWindow
- HaxeApp Canvas -> HaxeCanvasView


- [ ] Get lib loaded and call haxeInitialize()
    - Maybe following this is simplest

- Android build
    - What about having no java and doing everything in the C++ JNI wrapper?
        - Need quite a bit of glue probably for the OpenGLView
        - Would be nice to have a ready made touch setup
            - Maybe we can do this via C++ too?
        - We can do a fully native app
            - But then you can't easily embed in a java app
        ! Assets?
    - aar https://medium.com/@yushulx/how-to-build-so-library-files-into-aar-bundle-in-android-studio-a44387c9a012
        - https://developer.android.com/studio/projects/android-library.html#aar-contents
        - I don't like this if it requires android studio to compile stuff to .jar
        - aar files are zipped
    - What about some kind of subproject (library module)
        - This is stupid too because android _copies_ the library module
        - Maybe this https://stackoverflow.com/questions/24658422/android-studio-creating-modules-without-copying-files


- iOS Keyboard events

- [ ] Settings files per system
    - [ ] local storage
    - [ ] iOS/macOS settings CFPreferences
    - [ ] Android settings
    - [ ] Windows - Registry or local file?
    - [ ] Default, save to local file


- API renaming
    -> Is 'HaxeApp' clear enough? Should it be renamed to reflect it's a native-facing interface?

- [ ] Cursor setting
    Need a way to set the current cursor for the view
    Maybe: HaxeApp.setCursor(appInstance)?
    - [ ] Pointer
    - [ ] Hand
    - [ ] Hidden
    - [ ] *other css pointers

- [ ] Pass arbitrary message to haxe
    - What should the signature look like?
    - Allow native payload?
    - Require JSON?

- [ ] New desktop demo

- Review calling finalizers if throw when contructing

# Future

- Promises
    - Return promise for Image.decodeImageData and AudioContext.decodeAudioData

- WebGL
    - Implement extensions
    - Support for flipY and premultiply alpha

- Image.src
    - Loading images from `src` requires supporting event listeners so you can catch load complete

- Haxe's MainLoop doesn't appear thread safe X_X
    - Also we should sort _while inserting_
    - We should probably redefine so it wakes the event loop when a new event is added

- EventLoop per thread
    - We should use an event loop per thread so async code returns to the same thread for async callbacks and promises. For example
    ```
    main-thread {
        
        // do something async on another thread and callback to this thread
        start thread-2, readyCallback() {
            var callingThread = main-thread

            loadPlaceholder(onComplete: () => {
                // this should be running on thread-2, not the main thread (which is the current situation)
                // callback to whatever thread started this one
                runInThread(callingThread, readyCallback)
            })

        }

    }
    ```
    - Could also use thread pooling here

- hxcpp bug fixes
    - Replace usage of `gettimeofday` https://github.com/HaxeFoundation/hxcpp/issues/887

- Assets
    - support @:embed('directory') in AssetPack
    - Partial file reads
    - Chunk file load so we can cancel mid-load

- 2D UI via platform WebView
    - Compile UI code to js via a bridge class (uses macro to compile that portion of the codebase to js)

- Maybe Switch to dynamic libraries so we can link with system libraries during haxe compile (and not platform compile). Or add metadata to add flags to platform projects