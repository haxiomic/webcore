package wc.webgl;
import wc.webgl.GLContext;

typedef GLActiveInfo = {
	var size(default, null):GLint;
	var type(default, null):UniformType;
	var name(default, null):String;
}