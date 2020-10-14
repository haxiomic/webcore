package webcore.gl;
#if js
typedef GLProgram = js.html.webgl.Program;
#else
typedef GLProgram = webcore.gl.native.GLProgram;
#end