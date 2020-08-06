package wc.webgl;

#if js
typedef GLTexture = js.html.webgl.Texture;
#else
typedef GLTexture = wc.webgl.native.GLTexture;
#end