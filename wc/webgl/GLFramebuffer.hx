package wc.webgl;

#if js
typedef GLFramebuffer = js.html.webgl.Framebuffer;
#else
typedef GLFramebuffer = wc.webgl.native.GLFramebuffer;
#end