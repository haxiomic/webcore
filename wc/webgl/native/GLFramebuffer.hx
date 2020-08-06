package wc.webgl.native;

@:allow(wc.webgl.native.GLContext)
@:noCompletion
final class GLFramebuffer extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteFramebuffer(this);
	}

}