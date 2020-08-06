package wc.webgl.native;

@:allow(wc.webgl.native.GLContext)
@:noCompletion
final class GLRenderbuffer extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteRenderbuffer(this);
	}

}