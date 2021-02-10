import app.event.PointerType;
import app.event.KeyboardEvent;
import app.event.WheelEvent;
import app.event.PointerEvent;
import webgl.GLContextAttributes;
import audio.AudioContext;
import webgl.GLUniformLocation;
import webgl.GLTexture;
import webgl.GLBuffer;
import webgl.GLProgram;
import webgl.GLShader;
import webgl.GLContext;
import typedarray.Float32Array;
import typedarray.Uint8Array;

@:copyToBundle('../assets')
class DemoAssets implements app.AssetPack { }

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
@:expose
class App implements app.HaxeAppInterface {

	#if js
	static public function create(?canvas: js.html.CanvasElement, ?webglContextAttributes: GLContextAttributes) {
		var appInstance = new App();
		return new app.web.HaxeAppCanvas(appInstance, canvas, webglContextAttributes);
	}
	#end

	var width: Float = 0;
	var height: Float = 0;

	var gl: Null<GLContext>;
	var audioContext: AudioContext;
	var program: GLProgram;
	var triangleBuffer: GLBuffer;
	var texture: GLTexture;

	var circleVertexBuffer: GLBuffer;
	var circleIndexBuffer: GLBuffer;
	var circleVertexCount: Int;

	var uTexture: GLUniformLocation;
	var uTranslation: GLUniformLocation;
	var uScale: GLUniformLocation;
	var uIsPrimary: GLUniformLocation;

	var activePointerTypes = new Map<String, Map<Int, PointerEvent>>();

	public function new() {
		trace('App instance created. Language: ${device.DeviceInfo.getSystemLanguageIsoCode()}');

		// test the haxe event loop
		function helloLoop() {
			haxe.Timer.delay(helloLoop, 50);
			#if cpp
			cpp.vm.Gc.run(true);
			trace('hello', haxe.Timer.stamp(), '${cpp.vm.Gc.memInfo(cpp.vm.Gc.MEM_INFO_CURRENT) / 1e6}MB');
			#end
		}

		// helloLoop();

		// play a song
		trace('about to create audio context');
		audioContext = new AudioContext();
		trace('audio context = $audioContext');

		var volumeNode = audioContext.createGain();
		volumeNode.connect(audioContext.destination);
		volumeNode.gain.value = 1.0;

		var node = audioContext.createBufferSource();
		node.connect(volumeNode);
		

		var t0 = haxe.Timer.stamp();
		DemoAssets.readFile(DemoAssets.paths.assets.audio.my_triangle_mp3, (arraybuffer) -> {
			audioContext.decodeAudioData(arraybuffer, (audioBuffer) -> {
				trace('Trying to play audio', audioBuffer, haxe.Timer.stamp() - t0);
				node.buffer = audioBuffer;
				node.onended = () -> trace('Song ended');
				node.start();
			});
		},
		(error) -> {
			trace('Error loading audio file: $error');
		});
	}

	public function onResize(width: Float, height: Float) {
		this.width = width;
		this.height = height;

		trace('onResize', width, height);
	}

	public function onGraphicsContextReady(gl: GLContext) {
		this.gl = gl;

		trace(gl.getContextAttributes());

		// create programs
		program = try {
			var vertexShader = compileShader(vertexShaderSource, VERTEX_SHADER);
			var fragmentShader = compileShader(fragmentShaderSource, FRAGMENT_SHADER);
			linkProgram(vertexShader, fragmentShader);
		} catch (e: String) {
			throw e;
			null;
		}
		
		uTexture = gl.getUniformLocation(program, 'uTexture');
		uTranslation = gl.getUniformLocation(program, 'uTranslation');
		uScale = gl.getUniformLocation(program, 'uScale');
		uIsPrimary = gl.getUniformLocation(program, 'uIsPrimary');

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
		
		DemoAssets.readFile(DemoAssets.paths.assets.image.red_panda_jpg, (arraybuffer) -> {	
			image.Image.decodeImageData(arraybuffer,
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
		});

		// create a circle
		var sides = 30;
		var radius = 1;
		// Array({x,y})
		var circleVertices = new Float32Array((sides + 1) * 2);
		for (i in 0...sides) {
			var t = i / sides;
			var angle = t * 2 * Math.PI;
			var x = Math.cos(angle) * radius;
			var y = Math.sin(angle) * radius;
			circleVertices[i * 2 + 0] = x;
			circleVertices[i * 2 + 1] = y;
		}
		// indices
		var circleIndices = new Uint8Array(sides * 3);
		for (i in 0...sides) {
			circleIndices[i * 3 + 0] = i;
			circleIndices[i * 3 + 1] = (i + 1) % (sides);
			circleIndices[i * 3 + 2] = sides;
		}

		circleVertexBuffer = gl.createBuffer();
		gl.bindBuffer(ARRAY_BUFFER, circleVertexBuffer);
		gl.bufferData(ARRAY_BUFFER, circleVertices, STATIC_DRAW);

		circleIndexBuffer = gl.createBuffer();
		gl.bindBuffer(ELEMENT_ARRAY_BUFFER, circleIndexBuffer);
		gl.bufferData(ELEMENT_ARRAY_BUFFER, circleIndices, STATIC_DRAW);

		circleVertexCount = circleIndices.length;

		gl.disable(CULL_FACE);
	}

	public function onGraphicsContextLost() {
		trace('Graphics context lost');
		gl = null;
	}

	public function onDrawFrame(drawingBufferWidth: Int, drawingBufferHeight: Int) {
		var t_s = haxe.Timer.stamp();

		gl.viewport(0, 0, drawingBufferWidth, drawingBufferHeight);

		// execute commands on the OpenGL context
		gl.clearColor(0.0, Math.cos(t_s * 0.5), Math.sin(t_s * 0.3), 1);
		gl.clear(COLOR_BUFFER_BIT);

		gl.useProgram(program);

		// texture is at unit 0
		gl.uniform1i(uTexture, 0);

		var aspectRatio = drawingBufferWidth / drawingBufferHeight;

		gl.bindBuffer(ARRAY_BUFFER, circleVertexBuffer);
		gl.enableVertexAttribArray(0);
		gl.vertexAttribPointer(0, 2, FLOAT, false, 0, 0);
		gl.bindBuffer(ELEMENT_ARRAY_BUFFER, circleIndexBuffer);

		for (pointers in activePointerTypes) {
			for (pointer in pointers) {
				var x = (pointer.x / width) * 2 - 1;
				var y = -((pointer.y / height) * 2 - 1);
				var scale = (pointer.pressure + 1);
				var scaleX = pointer.width / width;
				var scaleY = pointer.height / width;
				if (pointer.pointerType == MOUSE) {
					scale = 20;
				}
				gl.uniform2f(uScale, scale * scaleX, scale * scaleY * aspectRatio);
				gl.uniform2f(uTranslation, x, y);
				gl.uniform1f(uIsPrimary, pointer.isPrimary ? 1.0 : 0.0);
				gl.drawElements(TRIANGLES, circleVertexCount, UNSIGNED_BYTE, 0);
			}
		}
	}

	public function onPointerDown(event: PointerEvent) {
		trace('down', event.pointerId, event.button, event.buttons);
		audioContext.resume();
		// ignore right mouse click
		if (event.button == 2) return false;
		getActivePointers(event.pointerType).set(event.pointerId, event);
		return false;
	}

	public function onPointerMove(event: PointerEvent) {
		var activePointers = getActivePointers(event.pointerType);
		if (activePointers.exists(event.pointerId)) {
			activePointers.set(event.pointerId, event);
		}
		return false;
	}

	public function onPointerUp(event: PointerEvent) {
		trace('up', event.pointerId, event.button, event.buttons);
		getActivePointers(event.pointerType).remove(event.pointerId);
		return false;
	}

	public function onPointerCancel(event: PointerEvent) {
		return onPointerUp(event);
	}

	public function onWheel(event: WheelEvent) {
		trace('wheel', event);
		return true;
	}

	public function onKeyDown(event: KeyboardEvent, hasFocus: Bool) {
		trace('keydown', hasFocus, event.key, event.code, event.location);
		return false;
	}

	public function onKeyUp(event: KeyboardEvent, hasFocus: Bool) {
		trace('keyup', hasFocus, event.key, event.code, event.location);
		return false;
	}

	public function onActivate() {
		trace('onActivate');
	}

	public function onDeactivate() {
		trace('onDeactivate');
	}

	function getActivePointers(type: PointerType) {
		var activePointers = activePointerTypes.get(type);
		if (activePointers == null) {
			activePointers = new Map();
			activePointerTypes.set(type, activePointers);
		}
		return activePointers;
	}

	function releaseGraphicsResources() {
		if (gl != null) {
			// WebGL objects are garbage collected in js but because the browser cannot properly estimate the memory pressure (small-handles in js, big on GPU), they might not be collected when we want
			// so with WebGL it's always best to release manually
			gl.deleteProgram(program);
			gl.deleteBuffer(triangleBuffer);
			gl.deleteTexture(texture);
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

		uniform vec2 uTranslation;
		uniform vec2 uScale;
		uniform float uIsPrimary;

		varying vec2 vPosition;
		void main() {
			vPosition = position * vec2(1.0, -1.) * 0.5 + 0.5;

			gl_Position = vec4(position * uScale + uTranslation, 0., 1.);
		}
	';

	static var fragmentShaderSource = '
		#ifdef GL_ES
		precision highp float;
		precision highp sampler2D;
		#endif

		uniform float uIsPrimary;

		varying vec2 vPosition;

		uniform sampler2D uTexture;

		void main() {
			vec4 sample = texture2D(uTexture, vPosition);
			gl_FragColor = mix(sample, vec4(1., 0., 0., 1.), uIsPrimary);
		}
	';

}