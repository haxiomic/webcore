package webgl;

#if js
typedef GLTexture = js.html.webgl.Texture;
#else
typedef GLTexture = webgl.native.GLTexture;
#end