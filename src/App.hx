import gluon.webgl.GLBuffer;
import gluon.webgl.GLProgram;
import gluon.webgl.GLShader;
import gluon.webgl.GLContext;
import typedarray.Float32Array;

#if debug
// In debug mode we enable sanitizers to help validate correctness (at a performance cost)
// @:buildXml('
// <target id="haxe">
// 	<flag value="-fsanitize=address" />
// 	<flag value="-fsanitize=undefined" />
// 	<flag value="-fno-omit-frame-pointer" />
// </target>
// ')
#end
class App implements app.HaxeAppInterface {

	var gl: GLContext;
	var program: GLProgram;
	var triangleBuffer: GLBuffer;

	public function new() {
		trace('App instance created');
		#if cpp
		cpp.vm.Gc.setFinalizer(this, cpp.Function.fromStaticFunction(finalizer));
		#end
	}

	public function onGraphicsContextReady(gl: GLContext) {
		this.gl = gl;

		// create programs
		program = try {
			var vertexShader = compileShader(vertexShaderSource, VERTEX_SHADER);
			var fragmentShader = compileShader(fragmentShaderSource, FRAGMENT_SHADER);
			linkProgram(vertexShader, fragmentShader);
		} catch (e: String) {
			trace(e);
			null;
		}

		// create triangle buffer
		var angle = Math.PI * 2 / 3;
		var trianglePositionArray = new Float32Array([
			Math.sin(angle * 0), Math.cos(angle * 0),
			Math.sin(angle * 1), Math.cos(angle * 1),
			Math.sin(angle * 2), Math.cos(angle * 2),
		]);

		triangleBuffer = gl.createBuffer();
		gl.bindBuffer(ARRAY_BUFFER, triangleBuffer);
		gl.bufferData(ARRAY_BUFFER, trianglePositionArray, STATIC_DRAW);

		gl.disable(CULL_FACE);
	}

	public function onGraphicsContextLost() {
		trace('Graphics context lost');
	}

	public function onDrawFrame() {
		var t_s = haxe.Timer.stamp();

		// execute commands on the OpenGL context
		gl.clearColor(Math.sin(t_s * 0.1), Math.cos(t_s * 0.5), Math.sin(t_s * 0.3), 1);
		gl.clear(COLOR_BUFFER_BIT);

		gl.bindBuffer(ARRAY_BUFFER, triangleBuffer);
		gl.enableVertexAttribArray(0);
		gl.vertexAttribPointer(0, 2, FLOAT, false, 0, 0);
		gl.useProgram(program);
		gl.drawArrays(TRIANGLES, 0, 3);
	}

	function releaseGraphicsResources() {
		// WebGL objects are garbage collected in js but because the browser cannot properly estimate the memory pressure (small-handles in js, big on GPU), they might not be collected when we want
		// so with WebGL it's always best to release manually
		gl.deleteProgram(program);
		gl.deleteBuffer(triangleBuffer);
	}

	/**
		Compile shader with error checking (via throw)
		@throws String
	**/
	function compileShader(source: String, type: ShaderType): GLShader {
		var shader = gl.createShader(type);
		gl.shaderSource(shader, source);
		gl.compileShader(shader);

		if (!gl.getShaderParameter(shader, COMPILE_STATUS)) {
			var typeName = switch (type) {
				case VERTEX_SHADER: 'vertex';
				case FRAGMENT_SHADER: 'fragment';
			}
			throw '[${typeName} compile]: ${gl.getShaderInfoLog(shader)}';
		}

		return shader;
	}

	/**
		Link shaders into a program with error checking (via throw)
		@throws String
	**/
	function linkProgram(vertexShader: GLShader, fragmentShader: GLShader): GLProgram {
		var program = gl.createProgram();
		gl.attachShader(program, vertexShader);
		gl.attachShader(program, fragmentShader);
		gl.bindAttribLocation(program, 0, 'position');
		gl.linkProgram(program);

		if (!gl.getProgramParameter(program, LINK_STATUS)) {
			throw '[program link]: ${gl.getProgramInfoLog(program)}';
		}

		return program;
	}

	static var vertexShaderSource = '
		attribute vec2 position;

		varying vec2 vPosition;
		void main() {
			vPosition = position;

			gl_Position = vec4(position * 0.5, 0., 1.);
		}
	';

	static var fragmentShaderSource = '
		#ifdef GL_ES
		precision highp float;
		precision highp sampler2D;
		#endif

		varying vec2 vPosition;

		void main() {
			gl_FragColor = vec4(abs(vPosition), 0.5, 1.);
		}
	';

	static function finalizer(instance: App) {
		trace('[debug] App.finalizer()');
		if (instance.gl != null) {
			instance.releaseGraphicsResources();
		}
	}

}