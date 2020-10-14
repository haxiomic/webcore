package webcore.webgl;
#if js
typedef GLShader = js.html.webgl.Shader;
#else
typedef GLShader = webcore.webgl.native.GLShader;
#end