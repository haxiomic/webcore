package webgl;

#if js
typedef GLRenderbuffer = js.html.webgl.Renderbuffer;
#else
typedef GLRenderbuffer = webgl.native.GLRenderbuffer;
#end