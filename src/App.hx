import webgl.GLUniformLocation;
import webgl.GLTexture;
import webgl.GLBuffer;
import webgl.GLProgram;
import webgl.GLShader;
import webgl.GLContext;
import typedarray.Float32Array;

@:embedFile('../assets/my-triangle.mp3')
// @:embedFile('../assets/multi-channel-test.mp3')
@:embedFile('../assets/testcase.mp3')
@:embedFile('../assets/red-panda.jpg')
@:embedFile('../assets/pnggrad16rgb.png')
class Assets extends asset.Assets {

}

#if debug
// In debug mode we enable sanitizers to help validate correctness (at a performance cost)
// <target id="haxe">
	// <compilerflag value="-fno-omit-frame-pointer" />
	// <compilerflag value="-fsanitize=address" />
	// <compilerflag value="-fsanitize=thread" />
	// <compilerflag value="-fno-omit-frame-pointer" />
	// <compilerflag value="-fsanitize=address" />
// </target>
#end
class App implements app.HaxeAppInterface {

	var gl: Null<GLContext>;
	var program: GLProgram;
	var triangleBuffer: GLBuffer;
	var texture: GLTexture;
	var uTextureLoc: GLUniformLocation;

	public function new() {
		trace('App instance created');

		#if cpp
		cpp.vm.Gc.setFinalizer(this, cpp.Function.fromStaticFunction(finalizer));
		#end

		// test the haxe event loop
		function helloLoop() {
			haxe.Timer.delay(helloLoop, 1000);
			#if cpp
			cpp.vm.Gc.run(true);
			trace('hello', haxe.Timer.stamp(), '${cpp.vm.Gc.memInfo(cpp.vm.Gc.MEM_INFO_CURRENT) / 1e6}MB');
			#end
		}

		helloLoop();

		// play a song
		trace('about to create audio context');
		var audioContext = new audio.AudioContext();
		trace('audio context = $audioContext');

		var volumeNode = audioContext.createGain();
		volumeNode.connect(audioContext.destination);
		volumeNode.gain.value = 1.0;

		function volumeLoop() {
			haxe.Timer.delay(volumeLoop, 4);
			volumeNode.gain.value = Math.sin(haxe.Timer.stamp()) + 1.0; // 0 to 2
			trace('gain: ${volumeNode.gain.value}');
		}
		volumeLoop();

		var node = audioContext.createBufferSource();
		node.connect(volumeNode);

		var t0 = haxe.Timer.stamp();
		audioContext.decodeAudioData(Assets.my_triangle_mp3, (audioBuffer) -> {
			trace('Trying to play audio', audioBuffer, haxe.Timer.stamp() - t0);
			node.buffer = audioBuffer;
			node.start();
			node.onended = () -> {
				trace('Song ended');
			}
		});

		#if js
		js.Browser.window.addEventListener('click', () -> audioContext.resume());
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
			throw e;
			null;
		}
		
		uTextureLoc = gl.getUniformLocation(program, 'uTexture');

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

		// create texture
		texture = gl.createTexture();
		gl.activeTexture(TEXTURE0);
		gl.bindTexture(TEXTURE_2D, texture);
		// null texture
		gl.texImage2D(TEXTURE_2D, 0, RGBA, 1, 1, 0, RGBA, UNSIGNED_BYTE, new typedarray.Uint8Array([0, 0, 255, 255]));

		var t0 = haxe.Timer.stamp();
		image.Image.decodeImageData(Assets.red_panda_jpg,
			(image) -> {
				trace('decodeImageData complete! ${image.naturalWidth}x${image.naturalHeight}', haxe.Timer.stamp() - t0);
				gl.activeTexture(TEXTURE0);
				gl.bindTexture(TEXTURE_2D, texture);

				var t0 = haxe.Timer.stamp();
				gl.texImage2DImageSource(TEXTURE_2D, 0, RGBA, RGBA, UNSIGNED_BYTE, image);

				if (isPowerOf2(image.width) && isPowerOf2(image.height)) {
					gl.generateMipmap(TEXTURE_2D);
				} else {
					// for non-power-of-2 images we need to set clamp wrapping and disable mip filtering
					gl.texParameteri(TEXTURE_2D, TEXTURE_WRAP_S, CLAMP_TO_EDGE);
					gl.texParameteri(TEXTURE_2D, TEXTURE_WRAP_T, CLAMP_TO_EDGE);
					gl.texParameteri(TEXTURE_2D, TEXTURE_MIN_FILTER, LINEAR);
				}

				trace('Uploaded texture', texture, haxe.Timer.stamp() - t0);
			},
			(error) -> {
				trace('decodeImageData failed: "$error"');
			},
			{
				nChannels: 4,
				dataType: UNSIGNED_BYTE,
			}
		);

		gl.disable(CULL_FACE);
	}

	public function onGraphicsContextLost() {
		trace('Graphics context lost');
		this.gl = null;
	}

	public function onDrawFrame() {
		var t_s = haxe.Timer.stamp();

		// execute commands on the OpenGL context
		gl.clearColor(Math.sin(t_s * 0.1), Math.cos(t_s * 0.5), Math.sin(t_s * 0.3), 1);
		gl.clear(COLOR_BUFFER_BIT);

		gl.useProgram(program);

		gl.bindBuffer(ARRAY_BUFFER, triangleBuffer);
		gl.enableVertexAttribArray(0);
		gl.vertexAttribPointer(0, 2, FLOAT, false, 0, 0);

		// texture is at unit 0
		gl.uniform1i(uTextureLoc, 0);

		gl.drawArrays(TRIANGLES, 0, 3);
	}

	function releaseGraphicsResources() {
		if (this.gl != null) {
			// WebGL objects are garbage collected in js but because the browser cannot properly estimate the memory pressure (small-handles in js, big on GPU), they might not be collected when we want
			// so with WebGL it's always best to release manually
			gl.deleteProgram(program);
			gl.deleteBuffer(triangleBuffer);
		}
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
			throw '[${typeName} compile error]: ${gl.getShaderInfoLog(shader)}';
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
			throw '[program link error]: ${gl.getProgramInfoLog(program)}';
		}

		return program;
	}

	function isPowerOf2(x: Int) {
		return x == 1 || (x & (x-1)) == 0;
	}

	static var vertexShaderSource = '
		attribute vec2 position;

		varying vec2 vPosition;
		void main() {
			vPosition = position * vec2(1.0, -1.) * 0.5 + 0.5;

			gl_Position = vec4(position * 0.5, 0., 1.);
		}
	';

	static var fragmentShaderSource = '
		#ifdef GL_ES
		precision highp float;
		precision highp sampler2D;
		#endif

		varying vec2 vPosition;

		uniform sampler2D uTexture;

		void main() {
			vec4 sample = texture2D(uTexture, vPosition);
			gl_FragColor = sample;
		}
	';

	static function finalizer(instance: App) {
		#if (debug && cpp)
		cpp.Stdio.printf("%s\n", "[debug] App.finalizer()");
		#end
	}

}