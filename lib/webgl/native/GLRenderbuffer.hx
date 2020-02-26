package webgl.native;

@:allow(webgl.native.GLContext)
final class GLRenderbuffer extends GLObject {

    @:noCompletion
    override public function finalize() {
        context.deleteRenderbuffer(this);
        handle = 0;
    }

}