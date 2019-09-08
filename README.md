# Minimal Haxe OpenGL Example

This example generates cross-platform native libraries that execute OpenGL commands when given an OpenGL context. The source code does not define an entry point (i.e. `static function main`), instead, it exposes a C-API that is used to initialize and communicate with the haxe code from the native platform

The host app is written natively for each platform, which for this example is just an empty app with an OpenGL view. All the native host apps are stored in the `targets` directory

Using OpenGL requires linking with different libraries, using different headers and a slightly different API on different platforms. To handle these differences this example uses [gluon](https://github.com/haxiomic/gluon) as a unified OpenGL ES 2.0 interface. It normalizes API differences, handles linking with system libraries when building with hxcpp and adds a layer of haxe-strict-typing to the OpenGL API. It provides a C++ implementation of JavaScripts TypedArrays as unified buffer type



## Build Instructions

- Install haxe 4, tested with [Haxe 4.0.0-rc.4](https://haxe.org/download/version/4.0.0-rc.4/)
- Clone this repository *with submodules*:  `git clone --recursive https://github.com/haxiomic/teach-your-monster-minimal-gl`


If you forget to clone with submodules you can pull and update submodules at any time with `git submodule update --init --recursive`

### iOS

Open the Xcode project in `targets/ios/MinimalGLApp` and build to see it running. During the app build process it will trigger the haxe to be recompiled via a Build Phase run script in `targets/ios/MinimalGLFramework`.

### Android

### Desktop

### Web

Run `haxe web.hxml` then open `targets/web/index.html` to see the output