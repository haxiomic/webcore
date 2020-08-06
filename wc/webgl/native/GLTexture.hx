package wc.webgl.native;

@:allow(webgl.native.GLContext)
@:noCompletion
final class GLTexture extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteTexture(this);
	}

}