package webcore.gl.native;

@:allow(webcore.gl.native.GLContext)
@:noCompletion
final class GLRenderbuffer extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteRenderbuffer(this);
	}

}