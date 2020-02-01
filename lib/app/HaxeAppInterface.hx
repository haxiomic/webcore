package app;

import gluon.webgl.GLContext;

/**
    Implement this interface to set the main app class.
    If the implementing class should not be the main app class then add `@:notMainApp`
**/
@:nativeGen
@:keep
#if !display
@:autoBuild(app.Macro.makeMainApp())
#end
interface HaxeAppInterface {

    function onGraphicsContextReady(gl: GLContext): Void;
    function onGraphicsContextLost(): Void;
    function onDrawFrame(): Void;

}