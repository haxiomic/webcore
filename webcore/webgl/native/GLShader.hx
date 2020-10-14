package webcore.webgl.native;

@:allow(webcore.webgl.native.GLContext)
@:noCompletion
final class GLShader extends GLObject {

	@:noCompletion
	override public function finalize() {
		context.deleteShader(this);
	}

}