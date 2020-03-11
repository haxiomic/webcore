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

	Generally input events follow the latest browser input specs, however there are small differences, for example: to prevent the platform's default handling for an event, return `true` from an event handling method
	- For mouse, touch and pen input, an interface that closely follows the PointerEvent API is used
	- Wheel events mirror browser [WheelEvent](https://developer.mozilla.org/en-US/docs/Web/API/WheelEvent) where all deltas are in units of **points**, normalizing for `deltaMode`
	- KeyboardEvents mirror browser [KeyboardEvent](https://w3c.github.io/uievents/#idl-keyboardevent) with an extra parameter `hasFocus` to detect if the view is focused for the event
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

	/**
		Graphics context is ready to be used. Save a reference to the context so it can be used in `onDrawFrame` and clear it when the context is lost.
	**/
	function onGraphicsContextReady(context: GLContext): Void;

	/**
		Called when the graphics context is invalidated (for example, the device encountered an error or needs to reclaim resources)
	**/
	function onGraphicsContextLost(): Void;

	/**
		- Only called after `onGraphicsContextReady` and stops after `onGraphicsContextLost`
		- `drawingBufferWidth` and `drawingBufferHeight` are the dimensions of the graphics context in **pixels**
	**/
	function onDrawFrame(drawingBufferWidth: Int, drawingBufferHeight: Int): Void;
	
	/**
		Called when a pointer (mouse, touch or pen) is activated, for a mouse this happens when a button is pressed.
		Return true to prevent default behavior.
		See https://www.w3.org/TR/pointerevents/#the-pointerdown-event
	**/
	function onPointerDown(event: PointerEvent): Bool;

	/**
		Called when an active pointer changes either position or pressure (if supported).
		Return true to prevent default behavior.
		See https://www.w3.org/TR/pointerevents/#the-pointermove-event
	**/
	function onPointerMove(event: PointerEvent): Bool;

	/**
		Called when a pointer (mouse, touch or pen) is activated, for a mouse this happens when a button is released.
		Return true to prevent default behavior.
		See https://www.w3.org/TR/pointerevents/#the-pointerup-event
	**/
	function onPointerUp(event: PointerEvent): Bool;

	/**
		Called when the pointer is unlikely to continue to produce events or the interaction was interrupted by a gesture recognition.
		Return true to prevent default behavior.
		See https://www.w3.org/TR/pointerevents/#the-pointercancel-event
	**/
	function onPointerCancel(event: PointerEvent): Bool;

	/**
		Called when a scroll interaction is performed on the view.
		Return true to prevent default behavior.
	**/
	function onWheel(event: WheelEvent): Bool;

	/**
		Called when a key is pressed down with the view focused.
		Return true to prevent default behavior.
		`hasFocus` is true if our view has input focus for the event
	**/
	function onKeyDown(event: KeyboardEvent, hasFocus: Bool): Bool;

	/**
		Called when a key is released with the view focused.
		Return true to prevent default behavior.
		`hasFocus` is true if our view has input focus for the event
	**/
	function onKeyUp(event: KeyboardEvent, hasFocus: Bool): Bool;

}

/**
	See https://developer.mozilla.org/en-US/docs/Web/API/WheelEvent
**/
@:publicFields
@:structInit
@:unreflective
class WheelEvent {

	/**
		The horizontal scroll amount in **points**, if scrolling a page this corresponds to the horizontal scroll distance that would be applied
	**/
	final deltaX: Float;

	/**
		The vertical scroll amount in **points**, if scrolling a page this corresponds to the vertical scroll distance that would be applied
	**/
	final deltaY: Float;

	/**
		Z-axis scroll amount (and 0 when unsupported)
	**/
	final deltaZ: Float;

	/**
		Horizontal position in units of **points** where 0 corresponds to the left of the view
	**/
	final x: Float;

	/**
		Vertical position in units of **points** where 0 corresponds to the top of the view
	**/
	final y: Float;

	final altKey: Bool;
	final ctrlKey: Bool;
	final metaKey: Bool;
	final shiftKey: Bool;

}

enum abstract PointerType(String) to String from String {
	var MOUSE = "mouse";
	var PEN = "pen";
	var TOUCH = "touch";
}

/**
	See https://www.w3.org/TR/pointerevents
**/
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
		Horizontal position in units of **points** where 0 corresponds to the left of the view
	**/
	final x: Float;

	/**
		Vertical position in units of **points** where 0 corresponds to the top of the view
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

/**
	See https://w3c.github.io/uievents/#dom-keyboardevent-dom_key_location_standard
**/
enum abstract KeyLocation(Int) to Int from Int {
	var STANDARD = 0;
	var LEFT = 1;
	var RIGHT = 2;
	var NUMPAD = 3;
}

/**
	See https://w3c.github.io/uievents/#idl-keyboardevent
**/
@:publicFields
@:structInit
@:unreflective
class KeyboardEvent {

	/**
		Locale-aware key

		Either a
		- A key string that corresponds to the character typed (accounting for the user's current locale and mappings), e.g. `"a"`
		- A named key mapping to the values in the [specification](https://www.w3.org/TR/uievents-key/#named-key-attribute-value) e.g. `"ArrowDown"`

		Example use-cases include detecting keyboard shortcuts

		See https://www.w3.org/TR/uievents-key/#key-attribute-value
	**/
	final key: String;

	/**
		A string that identifies the physical key being pressed, it differs from the `key` field in that it **doesn't** account for the user's current locale and mappings.
		The list of possible codes and their mappings to physical keys is given here https://www.w3.org/TR/uievents-code/.

		Example use-cases include detecting WASD keys for moving controls in a game

		See https://w3c.github.io/uievents/#keys-codevalues
	**/
	final code: String;

	final location: KeyLocation;

	final altKey: Bool;
	final ctrlKey: Bool;
	final metaKey: Bool;
	final shiftKey: Bool;

}