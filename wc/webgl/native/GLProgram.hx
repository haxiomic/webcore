package wc.webgl.native;

@:allow(wc.webgl.native.GLContext)
@:noCompletion
final class GLProgram extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteProgram(this);
	}

}