package app;

import gluon.es2.GLContext;

/**
    Implement this interface to set the main app class.
    If the implementing class should not be the main app class then add `@:notMainApp`
**/
@:nativeGen
@:keep
@:autoBuild(app.Macro.makeMainApp())
interface AppInterface {

    function onGraphicsContextReady(gl: GLContext): Void;
    function onGraphicsContextLost(): Void;
    function onDrawFrame(gl: GLContext): Void;

}