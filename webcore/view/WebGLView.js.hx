package webcore.view;

import js.Browser.*;
import webcore.gl.GLContext;
import webcore.gl.GLContextAttributes;

@:nullSafety
class WebGLView extends View {

	final gl: GLContext;

	@:noCompletion var requestAnimationFrameHandle = -1;

	public function new(contextAttributes: GLContextAttributes) {
		super();

		function frameLoop(_) @:nullSafety(Off) {
			onDrawFrame(window.performance.now(), gl.drawingBufferWidth, gl.drawingBufferHeight);
			requestAnimationFrameHandle = window.requestAnimationFrame(frameLoop);
		}

		var canvas = document.createCanvasElement();
		canvas.style.position = 'absolute';
		canvas.style.display = 'block';
		canvas.style.width = '100%';
		canvas.style.height = '100%';
		// ignore input as this is handled by the parent view
		canvas.style.pointerEvents = 'none';
		canvas.style.touchAction = 'none';
		canvas.setAttribute('touch-action', 'none');

		// add canvas gl context listeners to encourage powerPreference to be respected
		canvas.addEventListener('webglcontextlost', () -> @:nullSafety(Off) {
			onGraphicsContextLost();
			stopFrameLoop();
		});
		canvas.addEventListener('webglcontextrestored', () -> @:nullSafety(Off) {
			onGraphicsContextRestored();
			frameLoop(0);
		});

		this.gl = canvas.getContextWebGL(contextAttributes);

		nativeView.appendChild(canvas);

		frameLoop(0);
	}

	/**
		`drawingBufferWidth` and `drawingBufferHeight` are the dimensions of the graphics context in **pixels** (and therefore can be larger than this view's `width` and `height` on high pixel-ratio displays)
	**/
	function onDrawFrame(time_ms: Float, drawingBufferWidth: Int, drawingBufferHeight: Int): Void {}

	/**
		Called when the graphics context is invalidated (for example, the device encountered an error or needs to reclaim resources).
		See https://www.khronos.org/registry/webgl/specs/latest/1.0/#5.15.2
	**/
	function onGraphicsContextLost(): Void {}

	/**
		Graphics context is ready to be used again after the graphics context has been lost.
		See https://www.khronos.org/registry/webgl/specs/latest/1.0/#5.15.3
	**/
	function onGraphicsContextRestored(): Void {}

	/**
		After execution, no more calls to onDrawFrame will be made. Call this before disposing of a WebGLView
	**/
	function stopFrameLoop() {
		window.cancelAnimationFrame(requestAnimationFrameHandle);
		requestAnimationFrameHandle = -1;
	}

}