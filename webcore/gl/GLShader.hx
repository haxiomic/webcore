package webcore.gl;
#if js
typedef GLShader = js.html.webgl.Shader;
#else
typedef GLShader = webcore.gl.native.GLShader;
#end