import cpp.Pointer;
import cpp.NativeArray;
import audio.native.MiniAudio;
import audio.native.AudioOut;
import audio.native.AudioSource;
import typedarray.Float32Array;
import gluon.es2.GLBuffer;
import gluon.es2.GLProgram;
import gluon.es2.GLShader;
import gluon.es2.GLContext;
import haxe.Timer;

@:expose
class MinimalGL implements MinimalGLNativeInterface {

	final gl: GLContext;
	final program: GLProgram;
	final triangleBuffer: GLBuffer;

	public function new(gl) {
		this.gl = gl;
		trace('MinimalGL created');

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

		var audioOut = AudioOut.create();

		if (audioOut != null) {
			Console.examine(audioOut.maDevice.sampleRate);
			Console.examine(audioOut.maDevice.pContext.backend);
			Console.examine(audioOut.maDevice.playback.format);
			Console.examine(audioOut.maDevice.playback.internalFormat);
			Console.examine(audioOut.maDevice.playback.channels);
			Console.examine(audioOut.maDevice.playback.internalChannels);
			Console.examine(audioOut.sourceCount());
		}

		var multiChannelTest = AudioSource.createFileSource(
			'/Users/geo/Projects/teach-your-monster-native-media/src/audio/multi-channel-test.mp3',
			audioOut.maDevice.playback.channels,
			audioOut.maDevice.sampleRate
		);
		Console.examine(multiChannelTest);

		var twoChannelSong = AudioSource.createFileSource(
			'/Users/geo/Projects/teach-your-monster-native-media/src/audio/two-channel.mp3',
			audioOut.maDevice.playback.channels,
			audioOut.maDevice.sampleRate
		);
		Console.examine(twoChannelSong);

		// test add null source
		// Console.examine(audioOut.addSource(null), audioOut.sourceCount());
		// audioOut.removeSource(null);
		// Console.examine(audioOut.sourceCount());

		Console.log('Testing source');
		audioOut.addSource(multiChannelTest);
		audioOut.addSource(twoChannelSong);
		audioOut.addSource(multiChannelTest);

		Console.examine(audioOut.sourceCount());

		audioOut.removeSource(multiChannelTest);
		audioOut.removeSource(twoChannelSong);
		audioOut.removeSource(multiChannelTest);
		audioOut.removeSource(multiChannelTest);

		Console.examine(audioOut.sourceCount());

		audioOut.addSource(multiChannelTest);
		audioOut.addSource(twoChannelSong);
		audioOut.start();

		Timer.delay(() -> {
			var testcase = AudioSource.createFileSource(
				'/Users/geo/Projects/teach-your-monster-native-media/src/audio/testcase.mp3',
				audioOut.maDevice.playback.channels,
				audioOut.maDevice.sampleRate
			);
			audioOut.addSource(testcase);
			audioOut.removeSource(twoChannelSong);
		}, 2000);

		/*
		Timer.delay(() -> {
			audioOut.removeSource(fileSource);
			Console.log('Destorying AudioSource');
			AudioSource.destroy(fileSource);
			Console.log('Destorying AudioOut');
			AudioOut.destroy(audioOut);
		}, 4000);
		*/

		// AudioDevice.destroy(audioDevice);

		/*
		final audioContext: AudioContext;

		final testBufferSource: AudioBufferSourceNode;
		// test WebAudio API
		var soundBytes = haxe.crypto.Base64.decode(audio.TestCase.base64);
		
		audioContext = new audio.AudioContext();
		testBufferSource = audioContext.createBufferSource();

		audioContext.decodeAudioData(soundBytes.getData(), (audioBuffer) -> {
			trace('decoded audio buffer', audioBuffer);

			testBufferSource.buffer = audioBuffer;
			testBufferSource.connect(audioContext.destination);
			testBufferSource.onended = () -> {
				trace('testBufferSource.onended');
			}
		});	
		*/
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