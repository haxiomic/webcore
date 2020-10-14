package webcore.gl.native;

@:allow(webcore.gl.native.GLContext)
@:noCompletion
final class GLShader extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteShader(this);
	}

}