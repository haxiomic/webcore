package webcore.webgl;
#if js
typedef GLBuffer = js.html.webgl.Buffer;
#else
typedef GLBuffer = webcore.webgl.native.GLBuffer;
#end