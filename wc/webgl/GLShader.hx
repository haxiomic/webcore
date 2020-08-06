package wc.webgl;
#if js
typedef GLShader = js.html.webgl.Shader;
#else
typedef GLShader = wc.webgl.native.GLShader;
#end