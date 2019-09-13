# Haxe Minimal Cross-Platform OpenGL Example

<img src="https://user-images.githubusercontent.com/3742992/64806667-8fb9ce00-d58b-11e9-9f4a-bf82f83eeba9.png">

**Core idea**: The haxe code compiles into a static library with a C-API. The haxe code's responsibility is to interface with cross-platform libraries to draw graphics and trigger audio and it doesn't need to be aware of the platform it's running on. For each target platform a host app is created in the platform's native toolkit. The host app links with the generated haxe library like any other native library and so is decoupled from the haxe source. Platform-specific code stays in the platform's native language, for example touch events are forwarded the haxe code via the C-API.

In this example project, the host apps are empty apps with an OpenGL view. Each frame the host app calls `drawFrame()` on the generated lib's C-API, this triggers the haxe code to execute OpenGL commands. The host apps for each platform is stored in `platform/`. To compile the haxe code and run the app, open the host app project (in Xcode or Android Studio) and click run, this will trigger haxe to rebuild the static library.

Using OpenGL requires linking with different libraries, using different headers and a slightly different API on different platforms. To handle these differences this example uses [gluon](https://github.com/haxiomic/gluon) as a unified OpenGL ES 2.0 interface. It normalizes API differences, handles linking with system libraries when building with hxcpp and adds a layer of haxe-strict-typing to the OpenGL API. For a unified buffer type between WebGL and C++ it provides a native implementation of JavaScripts TypedArrays.


## Getting Started

- Install haxe 4, tested with [Haxe 4.0.0-rc.5](https://haxe.org/download/version/4.0.0-rc.5/)
- Clone this repository **with submodules**:  `git clone --recursive https://github.com/haxiomic/teach-your-monster-minimal-gl`

If you forget to clone with submodules you can pull and update submodules at any time with `git submodule update --init --recursive`

### iOS

#### Build & Run
- Install Xcode (I used 10.3)
- Open the Xcode project in `platform/ios/MinimalGLApp` and build to see it running

#### Implementation Breakdown
- A framework is used to create a Swift module wrapper for the static library see `platform/ios/MinimalGLFramework`
- A *Run Script* in the framework is used to trigger a haxe rebuild of the static lib for the current architecture (x86_64 for simulator and arm64 for device)
- The framework's *Library Search Paths* are set to point to the generated libs (and differ for iOS and simulator builds)
- The framework links with the haxe generated static library
- The host app project embeds the framework project, this means the framework project (and haxe code) is recompiled when rebuilding the app (see `platform/ios/MinimalGLApp`)

### Android

#### Build & Run
- Install Android Studio (I used 3.5)
- Set the SDK directory to `~/SDKs/android-sdk/` on macOS & Linux and `C:\SDKs\android-sdk\`. If you want to place this elsewhere, see [Using a custom Android SDK location](#using-a-custom-android-sdk-location).
- Install NDK 20 and CMake:
  - With Android Studio open to any project, click Tools > SDK Manager
  - Make sure an SDK platform is installed (I used Android 9.0 but any should do)
  - From the SDK Tools tab check **NDK** and **CMake**

- Open `platform/android/MinimalGLApp` with Android Studio (wait for gradle sync) and click Run (selecting either device or emulator)

#### Implementation Breakdown
- Java cannot call C functions directly like Swift, so instead we need to create a wrapper using the Java Native Interface
- A C++ file, called `MinimalGLJNI.cpp` interfaces with the haxe code's C-API and exposes methods to Java
- A Java file called `MinimalGL.java` acts as the Java interface for the haxe code – its static methods map directly to the C++ JNI code
- CMake is used to compile the native wrapper and link with the haxe generated lib. `app/CMakeList.txt` controls building the C++ wrapper as well as triggering the haxe code to be recompiled

### Web

- Run `haxe web.hxml` then open `platform/web/index.html` to see the output :)

## Next Steps

- Forward touch events
- Handle display resize
- Use a macro to generate the platform interface (i.e, generate Swift and Java interfaces for the C-API)

## FAQ

### Using a custom Android SDK location
To compile for Android HXCPP needs to be able to find the NDK, the default place hxcpp searches is `~/SDKs/android-sdk/` for linux and macOS and `C:\SDKs\android-sdk\` for Windows. However, if you want to put these elsewhere, you can do any of:
  - Edit your system's `.hxcpp_config.xml` and change the location of `SDK_ROOT`
  - Add `-D SDK_ROOT` to `platform/android/build-lib.hxml`
  - set the environmental variable `SDK_ROOT`
