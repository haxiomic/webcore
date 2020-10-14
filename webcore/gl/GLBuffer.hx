package webcore.gl;
#if js
typedef GLBuffer = js.html.webgl.Buffer;
#else
typedef GLBuffer = webcore.gl.native.GLBuffer;
#end