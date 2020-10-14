package webcore.gl.native;

@:allow(webcore.gl.native.GLContext)
@:noCompletion
final class GLBuffer extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteBuffer(this);
	}

}