package webcore.webgl.native;

import cpp.NativeGc;
import webcore.webgl.GLContext.GLuint;

@:allow(webcore.webgl.native.GLContext)
@:noCompletion
class GLObject {

	final context: GLContext;
	var handle: GLuint;

	function new(context: GLContext, handle: GLuint) {
		this.context = context;
		this.handle = handle;
		NativeGc.addFinalizable(this, false);
	}

	@:noCompletion
	public function finalize() {
		// override this in extending classes
		handle = 0;
	}

}