package webcore.webgl.native;

@:allow(webcore.webgl.native.GLContext)
@:noCompletion
final class GLProgram extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteProgram(this);
	}

}