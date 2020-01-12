import gluon.es2.GLContext;

@:expose
class App implements app.AppInterface {

    public function new() {
        trace('App instance created');
    }

    public function onNativeGraphicsContextReady(gl: GLContext) {
        trace('onNativeGraphicsContextReady', gl);
    }

    public function onDrawFrame(gl: GLContext) {
        var t_s = haxe.Timer.stamp();

        // execute commands on the OpenGL context
        gl.clearColor(Math.sin(t_s * 0.1), Math.cos(t_s * 0.5), Math.sin(t_s * 0.3), 1);
        gl.clear(COLOR_BUFFER_BIT);
    }

}