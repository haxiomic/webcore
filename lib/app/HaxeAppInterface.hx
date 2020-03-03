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

    /**
        - Called immediately after `onGraphicsContextReady` and again whenever the graphics context is resized (via window resize for example)

        - `drawingBufferWidth` and `drawingBufferHeight` are the dimensions of the graphics context in pixels
        - `displayPixelRatio` is the ratio between the the drawing buffer dimensions and the displayed dimensions in the native platform coordinates.
            For example, in HTML a `px` does not correspond to a physical pixel, instead it corresponds to the size of a pixel _on a 96dpi display_, so it equates to 1/96th of 1 inch in real-world units
            A `px` is a useful unit because it's often an integer multiple of the size of a physical display pixel.
            If the user is using a high-dpi display with a pixel density of 192dpi then `displayPixelRatio` will be `2`

        - While the graphics context is lost, this method will not be called
    **/
    function onGraphicsContextResize(drawingBufferWidth: Int, drawingBufferHeight: Int, displayPixelRatio: Float): Void;

    /**
        Only called after `onGraphicsContextReady` and stops after `onGraphicsContextLost`
    **/
    function onDrawFrame(): Void;

}