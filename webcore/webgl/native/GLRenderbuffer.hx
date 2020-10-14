package webcore.webgl.native;

@:allow(webcore.webgl.native.GLContext)
@:noCompletion
final class GLRenderbuffer extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteRenderbuffer(this);
	}

}