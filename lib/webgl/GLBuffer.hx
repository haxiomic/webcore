package webgl;

#if js
typedef GLBuffer = js.html.webgl.Buffer;
#else
typedef GLBuffer = webgl.native.GLBuffer;
#end