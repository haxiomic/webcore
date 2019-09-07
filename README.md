# Minimal Haxe OpenGL Example

This example generates cross-platform native libraries that execute OpenGL commands when given an OpenGL context. The source code does not define an entry point (`static function main`), instead, it exposes a C-API that is used to initialize and communicate with the haxe code from the native platform

The host app is written natively for each platform, which for this example is just an empty app with an OpenGL view

[Unified OpenGL API, gluon, which implements a typedarray implementation for the C++ target and normalizes]

## Build Instructions

- Install haxe 4, tested with [Haxe 4.0.0-rc.4](https://haxe.org/download/version/4.0.0-rc.4/)
- Clone this repository *with submodules*:  `git clone --recursive https://github.com/haxiomic/teach-your-monster-minimal-gl`


If you forget to clone with submodules you can pull and update submodules at any time with `git submodule update --init --recursive`

### iOS

The iOS build is distributed as a framework and a demo app using the framework. Open the Xcode project in `targets/ios/MinimalGLDemo` and build to see it running. During the app build process it will trigger the haxe to be compiled

### Android

### Desktop

### Web

Run `haxe web.hxml` then open `targets/web/index.html` to see the output