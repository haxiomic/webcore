package app;

import gluon.es2.GLContext;

/**
    Extend this class to set the main app class. This is an alternative to implementing MainAppInterface
**/
@:notMainApp
class MainAppBase implements MainAppInterface {

    public function onGraphicsContextReady(gl: GLContext): Void { }
    public function onGraphicsContextLost(): Void { }
    public function onDrawFrame(gl: GLContext): Void { }

}