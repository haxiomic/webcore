package webcore.webgl.native;

@:allow(webcore.webgl.native.GLContext)
@:noCompletion
final class GLBuffer extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteBuffer(this);
	}

}