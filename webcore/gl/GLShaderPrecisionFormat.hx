package webcore.gl;
import webcore.gl.GLContext;

typedef GLShaderPrecisionFormat = {
	var rangeMin(default, null):GLint;
	var rangeMax(default, null):GLint;
	var precision(default, null):GLint;
}