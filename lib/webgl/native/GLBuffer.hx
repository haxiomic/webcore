package webgl.native;

@:allow(webgl.native.GLContext)
final class GLBuffer extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteBuffer(this);
	}

}