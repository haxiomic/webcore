package webgl;

#if js
typedef GLProgram = js.html.webgl.Program;
#else
typedef GLProgram = webgl.native.GLProgram;
#end