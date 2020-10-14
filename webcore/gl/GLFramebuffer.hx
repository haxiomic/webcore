package webcore.gl;
#if js
typedef GLFramebuffer = js.html.webgl.Framebuffer;
#else
typedef GLFramebuffer = webcore.gl.native.GLFramebuffer;
#end