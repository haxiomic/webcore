package webcore.gl.native;

@:allow(webcore.gl.native.GLContext)
@:noCompletion
final class GLFramebuffer extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteFramebuffer(this);
	}

}