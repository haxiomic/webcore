package webcore.gl;
#if js
typedef GLTexture = js.html.webgl.Texture;
#else
typedef GLTexture = webcore.gl.native.GLTexture;
#end