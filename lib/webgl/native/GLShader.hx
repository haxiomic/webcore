package webgl.native;

@:allow(webgl.native.GLContext)
final class GLShader extends GLObject {

    @:noCompletion
    override public function finalize() {
        context.deleteShader(this);
        handle = 0;
    }

}