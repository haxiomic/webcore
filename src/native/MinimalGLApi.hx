package native;

@:build(native.NativeMacro.addCApi('Minimal.h', 'Minimal.cpp'))
class MinimalGLApi {

    static public function create(width: Int, height: Int): IMinimalGL {
		var glContext = new gluon.es2.impl.ES2Context();
		return new MinimalGL(glContext);
	}

}