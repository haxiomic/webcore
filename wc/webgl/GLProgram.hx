package wc.webgl;
#if js
typedef GLProgram = js.html.webgl.Program;
#else
typedef GLProgram = wc.webgl.native.GLProgram;
#end