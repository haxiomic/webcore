package app;

import webgl.GLContext;

/**
    Implement this interface to set the main app class.
    If the implementing class should not be the main app class then add `@:notMainApp`

    **Units**
    - `points` - Abstract length units independent of the display's physical pixel density. All coordinates and dimensions in this API are given in units of `points`. In UIKit this maps the `points` unit, in Android the `density independent pixel` and in HTML it maps to the `px` unit
    - `pixels` - Corresponds to individually addressable values in a texture or display
    
    See [iOS Documentation: Points Verses Pixels](https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/GraphicsDrawingOverview/GraphicsDrawingOverview.html#//apple_ref/doc/uid/TP40010156-CH14-SW7)

    **Input**
    For mouse, touch and pen input, an interface that closely follows the PointerEvent API is used. However there are some key differences to makeup for shortcomings in the PointerEvent specification:
    - `onPointerMove` has been renamed to `onPointerChange`, unlike `onPointerMove`, `onPointerChange` will also be called if there's a change in pressure of the pointer
    - `tangentialPressure` has been removed
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
    
    function onPointerDown(event: PointerEvent): Void;
    /**
        Called when an active pointer changes either position or pressure (if supported)
    **/
    function onPointerChange(event: PointerEvent): Void;
    function onPointerUp(event: PointerEvent): Void;
    function onPointerCancel(event: PointerEvent): Void;

    function onGraphicsContextReady(context: GLContext): Void;
    function onGraphicsContextLost(): Void;

    /**
        - Only called after `onGraphicsContextReady` and stops after `onGraphicsContextLost`
        - `drawingBufferWidth` and `drawingBufferHeight` are the dimensions of the graphics context in **pixels**
    **/
    function onDrawFrame(drawingBufferWidth: Int, drawingBufferHeight: Int): Void;

}

enum abstract PointerType(String) to String from String {
    var MOUSE = "mouse";
    var PEN = "pen";
    var TOUCH = "touch";
}

// @:unreflective
// typedef PointerEvent = {

@:publicFields
@:structInit
@:unreflective
class PointerEvent {
    /**
        Unique identifier for the pointer.
        See https://www.w3.org/TR/pointerevents/#dom-pointerevent-pointerid
    **/
    final pointerId: Int;

    /**
        See https://www.w3.org/TR/pointerevents/#dom-pointerevent-pointertype
    **/
    final pointerType: PointerType;

    /**
        See https://www.w3.org/TR/pointerevents/#dfn-primary-pointer
    **/
    final isPrimary: Bool;

    /**
        Indicates button who's state-change caused the event
        - `-1` - no buttons changed since the last event
        - `0` - left mouse button or touch/pen contact
        - `1` - middle mouse button
        - `2` - right mouse button or pen barrel button
        - `3` - mouse back button
        - `4` - mouse forward button
        - `5` - pen eraser button

        See https://www.w3.org/TR/pointerevents/#the-button-property
    **/
    final button: Int;

    /**
        Current state of the pointer's buttons as a bitmask.
        See https://www.w3.org/TR/pointerevents/#the-buttons-property
    **/
    final buttons: Int;

    /**
        Horizontal position in units of **points** where 0 corresponds to the left of the views
    **/
    final x: Float;

    /**
        Vertical position in units of **points** where 0 corresponds to the top of the views
    **/
    final y: Float;
    
    /**
        Horizontal dimension in units of **points** For inputs with a contact size (defaults to 1 for point-like inputs)
    **/
    final width: Float;

    /**
        Vertical dimension in units of **points** For inputs with a contact size (defaults to 1 for point-like inputs)
    **/
    final height: Float;

    /**
        Normalized pressure ranging from 0 to 1. For hardware that does not support pressure this value will be 0.5.
        See https://www.w3.org/TR/pointerevents/#dom-pointerevent-pressure
    **/
    final pressure: Float;

    /**
        See https://www.w3.org/TR/pointerevents/#dom-pointerevent-tangentialpressure
    **/
    final tangentialPressure: Float;

    /**
        Pen tilt in the horizontal direction in units of **degrees**, ranging from -90 to 90.
        See https://www.w3.org/TR/pointerevents/#dom-pointerevent-tiltx
    **/
    final tiltX: Float;

    /**
        Pen tilt in the vertical direction in units of **degrees**, ranging from -90 to 90.
        See https://www.w3.org/TR/pointerevents/#dom-pointerevent-tilty
    **/
    final tiltY: Float;

    /**
        Clockwise rotation in units of **degrees** (see `rotationAngle` for touches https://w3c.github.io/touch-events/#dom-touch-rotationangle)
    **/
    final twist: Float;
}