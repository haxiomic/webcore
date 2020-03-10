package webgl.native;

@:allow(webgl.native.GLContext)
final class GLFramebuffer extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteFramebuffer(this);
	}

}