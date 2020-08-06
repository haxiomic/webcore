package wc.webgl.native;

@:allow(wc.webgl.native.GLContext)
@:noCompletion
final class GLBuffer extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteBuffer(this);
	}

}