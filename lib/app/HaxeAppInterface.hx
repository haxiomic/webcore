package app;

import webgl.GLContext;

/**
    Implement this interface to set the main app class.
    If the implementing class should not be the main app class then add `@:notMainApp`

    **Units**
    - `points` - Abstract length units independent of the display's physical pixel density. All coordinates and dimensions in this API are given in units of `points`. In UIKit this maps the `points` unit, in Android the `density independent pixel` and in HTML it maps to the `px` unit
    - `pixels` - Corresponds to individually addressable values in a texture or display
    
    See [iOS Documentation: Points Verses Pixels](https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/GraphicsDrawingOverview/GraphicsDrawingOverview.html#//apple_ref/doc/uid/TP40010156-CH14-SW7)
**/
@:nativeGen
@:keep
#if !display
@:autoBuild(app.Macro.makeMainApp())
#end
interface HaxeAppInterface {

    /**
        - Called once after the view has been created
        - Called _after_ the view has been resized
        - `width` and `height` are in units of **points**
    **/
    function onResize(width: Float, height: Float): Void;

    function onGraphicsContextReady(context: GLContext): Void;
    function onGraphicsContextLost(): Void;

    /**
        - Only called after `onGraphicsContextReady` and stops after `onGraphicsContextLost`
        - `drawingBufferWidth` and `drawingBufferHeight` are the dimensions of the graphics context in **pixels**
    **/
    function onDrawFrame(drawingBufferWidth: Int, drawingBufferHeight: Int): Void;

}