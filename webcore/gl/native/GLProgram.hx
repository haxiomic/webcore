package webcore.gl.native;

@:allow(webcore.gl.native.GLContext)
@:noCompletion
final class GLProgram extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteProgram(this);
	}

}