package wc.webgl.native;

@:allow(wc.webgl.native.GLContext)
@:noCompletion
final class GLShader extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteShader(this);
	}

}