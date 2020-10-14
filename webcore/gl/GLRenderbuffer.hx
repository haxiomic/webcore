package webcore.gl;
#if js
typedef GLRenderbuffer = js.html.webgl.Renderbuffer;
#else
typedef GLRenderbuffer = webcore.gl.native.GLRenderbuffer;
#end