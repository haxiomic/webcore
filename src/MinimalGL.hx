import asset.Assets;
import audio.AudioSprite;
import gluon.es2.GLBuffer;
import gluon.es2.GLContext;
import gluon.es2.GLProgram;
import gluon.es2.GLShader;
import haxe.Timer;
import typedarray.Float32Array;

@:expose
class MinimalGL implements MinimalGLNativeInterface {

	final gl: GLContext;
	final program: GLProgram;
	final triangleBuffer: GLBuffer;

	public function new(gl) {
		this.gl = gl;
		trace('MinimalGL created');

		// on sys platforms, set the cwd to the exe directory so file reads are relative to the exe 
		#if sys
		Sys.setCwd(haxe.io.Path.directory(Sys.programPath()));
		#end

		// create programs
		program = try {
			var vertexShader = compileShader(vertexShaderSource, VERTEX_SHADER);
			var fragmentShader = compileShader(fragmentShaderSource, FRAGMENT_SHADER);
			linkProgram(vertexShader, fragmentShader);
		} catch (e: String) {
			trace(e);
			NONE;
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

		// Audio demo:
		
		// play sound by creating a context and decoding the file manually:
		// var context = new AudioContext();
		// var bufferSource = context.createBufferSource();
		// bufferSource.connect(context.destination);
		// context.decodeAudioData(Assets.my_triangle_mp3.getData(), audioBuffer -> bufferSource.buffer = audioBuffer, err -> trace(err));
		// bufferSource.start();
		
		// alternatively a AudioSprite which does the above internally
		var audioSprite = new AudioSprite(Assets.my_triangle_mp3);
		audioSprite.play();
		
		// browsers require a user gesture to enable audio output, so call play() on window.onclick
		#if js
		{
			js.Browser.window.addEventListener('click', () -> audioSprite.play());
			// add a message to click
			var clickToPlayEl = js.Browser.document.createElement('div');
			js.Browser.document.body.appendChild(clickToPlayEl);
			clickToPlayEl.innerText = 'Click for audio';
			clickToPlayEl.style.color = 'white';
			clickToPlayEl.style.position = 'absolute';
			clickToPlayEl.style.zIndex = '100';
			clickToPlayEl.style.margin = 'auto';
			clickToPlayEl.style.font = '64px helvetica, sans-serif';
			clickToPlayEl.style.top = '0';
			clickToPlayEl.style.right = '0';
			clickToPlayEl.style.left = '0';
			clickToPlayEl.style.textAlign = 'center';
		}
		#end
	}

	public function drawFrame() {
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

}

/**
	This interface defines the native C++ API exposed by the component
**/
@:nativeGen
interface MinimalGLNativeInterface {

	@:keep public function drawFrame(): Void;

}