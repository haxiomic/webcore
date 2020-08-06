package webgl;

#if js
typedef GLFramebuffer = js.html.webgl.Framebuffer;
#else
typedef GLFramebuffer = webgl.native.GLFramebuffer;
#end