package webgl.native;

@:allow(webgl.native.GLContext)
final class GLTexture extends GLObject {

    @:noCompletion
    override public function finalize() {
        context.deleteTexture(this);
    }

}