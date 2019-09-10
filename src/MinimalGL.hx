import haxe.Timer;
import gluon.es2.GLContext;

@:expose
class MinimalGL implements MinimalGLNativeInterface {

	var gl: GLContext;

	public function new(gl) {
		this.gl = gl;
		trace('MinimalGL created');
	}

	public function drawFrame() {
		var t_s = haxe.Timer.stamp();

		// execute commands on the OpenGL context
		gl.clearColor(Math.sin(t_s * 0.1), Math.cos(t_s * 0.5), Math.sin(t_s * 0.3), 1);
		gl.clear(COLOR_BUFFER_BIT);
	}

}

/**
	This interface defines the native C++ API exposed by the component
**/
@:nativeGen
interface MinimalGLNativeInterface {

	@:keep public function drawFrame(): Void;

}