package webcore.webgl;
#if js
typedef GLProgram = js.html.webgl.Program;
#else
typedef GLProgram = webcore.webgl.native.GLProgram;
#end