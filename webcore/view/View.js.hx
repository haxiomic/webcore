package webcore.view;

import webcore.event.*;

import js.Browser.*;

typedef NativeView = js.html.DivElement;

/**
	**Units**

	- `points` - Abstract length units independent of the display's physical pixel density. All coordinates and dimensions in this API are given in units of `points`. In UIKit this maps the `points` unit, in Android the `density independent pixel` and in HTML it maps to the `px` unit
	- `pixels` - Corresponds to individually addressable values in a texture or display
	
	See [iOS Documentation: Points Verses Pixels](https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/GraphicsDrawingOverview/GraphicsDrawingOverview.html#//apple_ref/doc/uid/TP40010156-CH14-SW7)

	**Input**

	Generally input events follow the latest browser input event specifications, however there are small differences, for example: to prevent the platform's default handling for an event, return `true` from an event handling method
	- For mouse, touch and pen input, an interface that closely follows the PointerEvent API is used
	- Wheel events mirror browser [WheelEvent](https://developer.mozilla.org/en-US/docs/Web/API/WheelEvent) where all deltas are in units of **points**, normalizing for `deltaMode`
	- KeyboardEvents mirror browser [KeyboardEvent](https://w3c.github.io/uievents/#idl-keyboardevent) with an extra parameter `hasFocus` to detect if the view is focused for the event
**/
@:nullSafety
class View implements IView {

	/**
		View width in **points** units
	**/
	public var width (get, never): Float;
	/**
		View height in **points** units
	**/
	public var height (get, never): Float;

	public final nativeView: js.html.DivElement;

	public function new() {
		nativeView = document.createDivElement();

		// allow child elements to fill this element
		nativeView.style.position = 'relative';

		// provide a default size
		nativeView.style.width = '512px';
		nativeView.style.height = '256px';

		// disable default touch actions, this helps disable view dragging on touch devices
		nativeView.tabIndex = 1;
		nativeView.style.touchAction = 'none';
		nativeView.setAttribute('touch-action', 'none');
		// prevent native touch-scroll
		function cancelEvent(e) {
			e.preventDefault();
			e.stopPropagation();
		}
		nativeView.addEventListener('gesturestart', cancelEvent, false);
		nativeView.addEventListener('gesturechange', cancelEvent, false);

		var haxeAppActivated = false;
		function onVisibilityChange() {
			switch (document.visibilityState) {
				case VISIBLE: if (!haxeAppActivated) {
					this.onActivate();
					haxeAppActivated = true;
				}
				case HIDDEN: if (haxeAppActivated) {
					this.onDeactivate();
					haxeAppActivated = false;
				}
			}
		}

		function addPointerEventListeners() {
			// Pointer Input
			function executePointerMethodFromMouseEvent(mouseEvent: js.html.MouseEvent, pointerMethod: (webcore.event.PointerEvent) -> Bool) {
				// trackpad force
				// var force = mouseEvent.force || mouseEvent.webkitForce;
				var force: Float = if (js.Syntax.field(mouseEvent, 'force') != null) {
					js.Syntax.field(mouseEvent, 'force');
				} else if (js.Syntax.field(mouseEvent, 'webkitForce') != null) {
					js.Syntax.field(mouseEvent, 'webkitForce');
				} else {
					0.5;
				}

				// force ranges from 1 (WEBKIT_FORCE_AT_MOUSE_DOWN) to >2 when using a force-press
				// convert force to a 0 - 1 range
				var pressure = Math.max((force - 1), 0);

				if (pointerMethod({
					pointerId: 1,
					pointerType: 'mouse',
					isPrimary: true,
					button: mouseEvent.button,
					buttons: mouseEvent.buttons,
					x: mouseEvent.clientX,
					y: mouseEvent.clientY,
					width: 1,
					height: 1,
					pressure: pressure,
					tangentialPressure: 0,
					tiltX: 0,
					tiltY: 0,
					twist: 0,
				})) {
					mouseEvent.preventDefault();
				}
			}

			// Map<type, {primaryTouchIdentifier: Int, activeCount: Int}>
			var touchInfoForType = new Map<String, {primaryTouchIdentifier: Int, activeCount: Int}>();
			function getTouchInfoForType(type): {primaryTouchIdentifier: Int, activeCount: Int} {
				var touchInfo = touchInfoForType[type];
				if (touchInfo == null) {
					touchInfo = {
						primaryTouchIdentifier: null,
						activeCount: 0,
					};
					touchInfoForType[type] = touchInfo;
				}
				return touchInfo;
			}

			function executePointerMethodFromTouchEvent(touchEvent: js.html.TouchEvent, pointerMethod: (webcore.event.PointerEvent) -> Bool) {
				var buttonStates: {
					button: Int,
					buttons: Int,
				} = switch (touchEvent.type) {
					case 'touchstart': {
						button: 0,
						buttons: 1,
					}
					case 'touchforcechange', 'touchmove': {
						button: -1,
						buttons: 1,
					}
					default: {
						button: 0,
						buttons: 0,
					}
				}

				for (i in 0...touchEvent.changedTouches.length) {
					var touch: TouchLevel2 = cast touchEvent.changedTouches[i];

					// touchforcechange can fire _after_ touchup fires
					// we filter it out by checking if the touch is included in the list of active touches
					if (touchEvent.type == 'touchforcechange') {
						var touchIsActive = false;
						for (t in touchEvent.touches) {
							if (touch == cast t) {
								touchIsActive = true;
								break;
							}
						}
						if (!touchIsActive) {
							continue;
						}
					}

					var touchInfo = getTouchInfoForType(touch.touchType);

					// set primary touch as the first active touch
					if (touchInfo.activeCount == 0 && touchEvent.type == 'touchstart') {
						touchInfo.primaryTouchIdentifier = touch.identifier;
					}
					// update activeCount
					switch (touchEvent.type) {
						case 'touchstart':
							touchInfo.activeCount++;
						case 'touchend', 'touchcancel': 
							touchInfo.activeCount--;
					}

					// convert altitude-azimuth to tilt xy
					var tanAlt = Math.tan(touch.altitudeAngle);
					var radToDeg = 180.0 / Math.PI;
					var tiltX = Math.atan(Math.cos(touch.azimuthAngle) / tanAlt) * radToDeg;
					var tiltY = Math.atan(Math.sin(touch.azimuthAngle) / tanAlt) * radToDeg;

					var radiusX = touch.radiusX != null ? touch.radiusX : (js.Syntax.field(touch, 'webkitRadiusX') != null ? js.Syntax.field(touch, 'webkitRadiusX') : 5);
					var radiusY = touch.radiusY != null ? touch.radiusY : (js.Syntax.field(touch, 'webkitRadiusY') != null ? js.Syntax.field(touch, 'webkitRadiusY') : 5);

					if (pointerMethod({
						pointerId: touch.identifier,
						pointerType: (touch.touchType == 'stylus') ? 'pen' : 'touch',
						isPrimary: touch.identifier == touchInfo.primaryTouchIdentifier,
						button: buttonStates.button,
						buttons: buttonStates.buttons,
						x: touch.clientX,
						y: touch.clientY,
						width: radiusX * 2,
						height: radiusY * 2,
						pressure: touch.force,
						tangentialPressure: 0,
						tiltX: Math.isFinite(tiltX) ? tiltX : 0,
						tiltY: Math.isFinite(tiltY) ? tiltY : 0,
						twist: touch.rotationAngle,
					})) {
						touchEvent.preventDefault();
					}
				}
			}

			var onPointerDown = (e) -> this.onPointerDown(e);
			var onPointerMove = (e) -> this.onPointerMove(e);
			var onPointerUp = (e) -> this.onPointerUp(e);
			var onPointerCancel = (e) -> this.onPointerCancel(e);

			// use PointerEvent API if supported
			if (js.Syntax.field(window, 'PointerEvent')) {
				nativeView.addEventListener('pointerdown', onPointerDown);
				window.addEventListener('pointermove', onPointerMove);
				window.addEventListener('pointerup', onPointerUp);
				window.addEventListener('pointercancel', onPointerCancel);
			} else {
				nativeView.addEventListener('mousedown', (e) -> executePointerMethodFromMouseEvent(e, onPointerDown));
				window.addEventListener('mousemove', (e) -> executePointerMethodFromMouseEvent(e, onPointerMove));
				window.addEventListener('webkitmouseforcechanged', (e) -> executePointerMethodFromMouseEvent(e, onPointerMove));
				window.addEventListener('mouseforcechanged', (e) -> executePointerMethodFromMouseEvent(e, onPointerMove));
				window.addEventListener('mouseup', (e) -> executePointerMethodFromMouseEvent(e, onPointerUp));
				var useCapture = true;
				nativeView.addEventListener('touchstart', (e) -> executePointerMethodFromTouchEvent(e, onPointerDown), { capture: useCapture,  }); // passive: false
				window.addEventListener('touchmove', (e) -> executePointerMethodFromTouchEvent(e, onPointerMove), { capture: useCapture,  }); // passive: false
				window.addEventListener('touchforcechange', (e) -> executePointerMethodFromTouchEvent(e, onPointerMove), { capture: useCapture,  }); // passive: true
				window.addEventListener('touchend', (e) -> executePointerMethodFromTouchEvent(e, onPointerUp), {capture: useCapture, }); // passive: true
				window.addEventListener('touchcancel', (e) -> executePointerMethodFromTouchEvent(e, onPointerCancel), { capture: useCapture,  }); // passive: true
			}
		}

		function addWheelEventListeners() {
			nativeView.addEventListener('wheel', (e: js.html.WheelEvent) -> {
				// we normalize for delta modes, so we always scroll in px
				// chrome always uses pixels but firefox can sometime uses lines and pages
				// see https://stackoverflow.com/questions/20110224/what-is-the-height-of-a-line-in-a-wheel-event-deltamode-dom-delta-line
				var x_px = e.clientX;
				var y_px = e.clientY;
				var deltaX_px = e.deltaX;
				var deltaY_px = e.deltaY;
				var deltaZ_px = e.deltaZ;
				switch (e.deltaMode) {
					case js.html.WheelEvent.DOM_DELTA_PIXEL:
						deltaX_px = e.deltaX;
						deltaY_px = e.deltaY;
						deltaZ_px = e.deltaZ;
					case js.html.WheelEvent.DOM_DELTA_LINE:
						// lets assume the line-height is 16px
						deltaX_px = e.deltaX * 16;
						deltaY_px = e.deltaY * 16;
						deltaZ_px = e.deltaZ * 16;
					case js.html.WheelEvent.DOM_DELTA_PAGE:
						// this needs further testing
						deltaX_px = e.deltaX * 100;
						deltaY_px = e.deltaY * 100;
						deltaZ_px = e.deltaZ * 100;
				}
				if (this.onWheel({
					x: x_px,
					y: y_px,
					deltaX: deltaX_px,
					deltaY: deltaY_px,
					deltaZ: deltaZ_px,
					// deltaMode: e.deltaMode,
					altKey: e.altKey,
					ctrlKey: e.ctrlKey,
					metaKey: e.metaKey,
					shiftKey: e.shiftKey,
				})) {
					e.preventDefault();
				}
			});
		}

		function addKeyboardEventListeners() {
			// keyboard event
			window.addEventListener('keydown', (e: js.html.KeyboardEvent) -> {
				var hasFocus = e.target == nativeView;
				if (this.onKeyDown(cast e, hasFocus)) {
					e.preventDefault();
				}
			});
			window.addEventListener('keyup', (e) -> {
				var hasFocus = e.target == nativeView;
				if (this.onKeyUp(cast e, hasFocus)) {
					e.preventDefault();
				}
			});
		}

		function addLifeCycleEventListeners() {
			// life-cycle events
			document.addEventListener('visibilitychange', () -> onVisibilityChange());
		}

		addPointerEventListeners();
		addWheelEventListeners();
		addKeyboardEventListeners();
		addLifeCycleEventListeners();

		// startup life-cycle event
		onVisibilityChange();
	}

	/**
		Called when a pointer (mouse, touch or pen) is activated, for a mouse this happens when a button is pressed.
		Return true to prevent default behavior.
		See https://www.w3.org/TR/pointerevents/#the-pointerdown-event
	**/
	function onPointerDown(event: PointerEvent): Bool return false;

	/**
		Called when an active pointer changes either position or pressure (if supported).
		This is called when a cursor moves, whether or not any buttons are down.
		Return true to prevent default behavior.
		See https://www.w3.org/TR/pointerevents/#the-pointermove-event
	**/
	function onPointerMove(event: PointerEvent): Bool return false;

	/**
		Called when a pointer (mouse, touch or pen) is activated, for a mouse this happens when a button is released.
		Return true to prevent default behavior.
		See https://www.w3.org/TR/pointerevents/#the-pointerup-event
	**/
	function onPointerUp(event: PointerEvent): Bool return false;

	/**
		Called when the pointer is unlikely to continue to produce events or the interaction was interrupted by a gesture recognition.
		Return true to prevent default behavior.
		See https://www.w3.org/TR/pointerevents/#the-pointercancel-event
	**/
	function onPointerCancel(event: PointerEvent): Bool return false;

	/**
		Called when a scroll interaction is performed on the view.
		Return true to prevent default behavior.
		If `ctrlKey` is true, the event can be assumed to be a pinch gesture on a trackpad.
	**/
	function onWheel(event: WheelEvent): Bool return false;

	/**
		Called when a key is pressed down with the view focused.
		Return true to prevent default behavior.
		`hasFocus` is true if our view has input focus for the event. For `hasFocus` to be correct the canvas needs to be focusable. This requires setting the `tabIndex` attribute on the canvas
	**/
	function onKeyDown(event: KeyboardEvent, hasFocus: Bool): Bool return false;

	/**
		Called when a key is released with the view focused.
		Return true to prevent default behavior.
		`hasFocus` is true if our view has input focus for the event. For `hasFocus` to be correct the canvas needs to be focusable. This requires setting the `tabIndex` attribute on the canvas
	**/
	function onKeyUp(event: KeyboardEvent, hasFocus: Bool): Bool return false;

	/**
		Called when the haxe view goes from a deactivated state (hidden view, minimized tab, background-mode app) to a foreground active state.
		For example, you should use this event to resume activities and connect to sensor events.
		This method is called as early as possible in the transition and the view may not yet be visible.
		**It is called once at startup.**
	**/
	function onActivate(): Void {}

	/**
		Called before the app transitions into a deactivated state (hidden view, minimized tab, background-mode app).
		For example you should use this event to suspend activities to save power, pause a game, save state or disconnect from sensors.
		This method is called as early as possible in the transition and the view may still be visible.
	**/
	function onDeactivate(): Void {}

	@:noCompletion
	function get_width() {
		return nativeView.clientWidth;
	}

	@:noCompletion
	function get_height() {
		return nativeView.clientHeight;
	}

}

/**
	Adds missing fields to touch type in the level2 spec
**/
extern class TouchLevel2 extends js.html.Touch {
	var touchType: String;
	var altitudeAngle: Float;
	var azimuthAngle: Float;
}