package webgl.native;

@:allow(webgl.native.GLContext)
final class GLProgram extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteProgram(this);
	}

}