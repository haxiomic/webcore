import js.Browser.*;

@:expose
class Example2 extends wc.view.WebGLView {

	public function new() {
		super({
			alpha: false,
			preserveDrawingBuffer: false,
			premultipliedAlpha: false,
			antialias: false,
			stencil: false,
			depth: true,
		});
	}

	override function onDrawFrame(t_ms: Float, w: Float, h: Float) {
		var t_s = t_ms / 1000;
		console.log(t_s);
		gl.clearColor(Math.sin(t_s), Math.sin(t_s * 4 + 3), Math.sin(t_s * 0.5 - 3), 1);
		gl.clear(COLOR_BUFFER_BIT);
	}

}