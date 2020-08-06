package webgl.native;

@:allow(webgl.native.GLContext)
@:noCompletion
final class GLRenderbuffer extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteRenderbuffer(this);
	}

}