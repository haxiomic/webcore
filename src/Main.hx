import gluon.es2.GLContext;

class Main {

    var gl: GLContext;

    public function new() {
        trace('App instance created');
        app.HaxeNativeBridge.addEventHandler(this);
    }

    public function onNativeGraphicsContextReady(gl) {
        this.gl = gl;
    }

    public function onDrawFrame() {
        var t_s = haxe.Timer.stamp();

        // execute commands on the OpenGL context
        gl.clearColor(Math.sin(t_s * 0.1), Math.cos(t_s * 0.5), Math.sin(t_s * 0.3), 1);
        gl.clear(COLOR_BUFFER_BIT);
    }

    static function main() {
        trace('main()');
        var instance = new Main();
    }

}