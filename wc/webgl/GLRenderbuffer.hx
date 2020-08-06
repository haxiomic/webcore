package wc.webgl;

#if js
typedef GLRenderbuffer = js.html.webgl.Renderbuffer;
#else
typedef GLRenderbuffer = wc.webgl.native.GLRenderbuffer;
#end