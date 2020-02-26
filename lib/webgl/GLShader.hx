package webgl;

#if js
typedef GLShader = js.html.webgl.Shader;
#else
typedef GLShader = webgl.native.GLShader;
#end