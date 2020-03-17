- Message Jonathan

- [ ] Asset system
    - [ ] Platform native code
        - [ ] macro, move to embedded
        - [ ] support @:copyToBundle
            - bundles are named after the class and the name overridden with metadata
        - [ ] macro for readBundleFile that checks for file existence

- [ ] Device info
    - Screen size
    - systemLanguage

- [ ] Settings files per system
    - [ ] local storage?
    - [ ] iOS settings
    - [ ] Android settings
    - [ ] Desktop to file? Or Windows/mac settings?

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

- Generate an .aar for easy Android integration
    https://medium.com/@yushulx/how-to-build-so-library-files-into-aar-bundle-in-android-studio-a44387c9a012

- [ ] New desktop demo

- [ ] Some way to supply platform view templates

- Review calling finalizers if throw when contructing

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

- Maybe Switch to dynamic libraries so we can link with system libraries during haxe compile (and not platform compile). Or add metadata to add flags to platform projects

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

- Assets
    - Partial file reads
    - Chunk file load so we can cancel mid-load

- 2D UI via platform WebView
    - Compile UI code to js via a bridge class (uses macro to compile that portion of the codebase to js)