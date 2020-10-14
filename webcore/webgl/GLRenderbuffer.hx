package webcore.webgl;
#if js
typedef GLRenderbuffer = js.html.webgl.Renderbuffer;
#else
typedef GLRenderbuffer = webcore.webgl.native.GLRenderbuffer;
#end