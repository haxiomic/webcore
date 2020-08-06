package wc.webgl;
#if js
typedef GLBuffer = js.html.webgl.Buffer;
#else
typedef GLBuffer = wc.webgl.native.GLBuffer;
#end