package webcore.gl.native;

@:allow(webcore.gl.native.GLContext)
@:noCompletion
final class GLTexture extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteTexture(this);
	}

}