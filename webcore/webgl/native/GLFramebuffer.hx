package webcore.webgl.native;

@:allow(webcore.webgl.native.GLContext)
@:noCompletion
final class GLFramebuffer extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteFramebuffer(this);
	}

}