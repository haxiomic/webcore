package webcore.webgl;
#if js
typedef GLTexture = js.html.webgl.Texture;
#else
typedef GLTexture = webcore.webgl.native.GLTexture;
#end