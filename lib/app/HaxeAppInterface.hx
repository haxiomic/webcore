package app;

import webgl.GLContext;

/**
    Implement this interface to set the main app class.
    If the implementing class should not be the main app class then add `@:notMainApp`
**/
@:nativeGen
@:keep
#if !display
@:autoBuild(app.Macro.makeMainApp())
#end
interface HaxeAppInterface {

    function onGraphicsContextReady(context: GLContext): Void;
    function onGraphicsContextLost(): Void;

    function onGraphicsContextResize(drawingBufferWidth: Int, drawingBufferHeight: Int, displayPixelRatio: Float): Void;

    /**
        - Only called after `onGraphicsContextReady` and stops after `onGraphicsContextLost`
        - `drawingBufferWidth` and `drawingBufferHeight` are the dimensions of the graphics context in pixels
    **/
    function onDrawFrame(drawingBufferWidth: Int, drawingBufferHeight: Int): Void;

}