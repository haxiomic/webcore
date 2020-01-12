package app;

import gluon.es2.GLContext;

@:nativeGen
@:keep
@:autoBuild(app.Macro.addAppInitialization())
interface AppInterface {

    function onNativeGraphicsContextReady(gl: GLContext): Void;
    function onDrawFrame(gl: GLContext): Void;

}