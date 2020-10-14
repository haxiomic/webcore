package webcore.webgl;
#if js
typedef GLFramebuffer = js.html.webgl.Framebuffer;
#else
typedef GLFramebuffer = webcore.webgl.native.GLFramebuffer;
#end