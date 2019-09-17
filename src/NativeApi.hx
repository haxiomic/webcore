/**
	This class adds the C-API to the hxcpp build
**/

#if !macro

@:nativeGen
@:build(NativeApi.Macro.addCApi('native/MinimalGLC.h', 'native/MinimalGLC.cpp'))
class NativeApi {

	@:keep static public function create(): MinimalGL.MinimalGLNativeInterface {
		var glContext = new gluon.es2.impl.ES2Context();
		return new MinimalGL(glContext);
	}

}

#else

import haxe.macro.Context;
import haxe.io.Path;

class Macro {

	/**
		Add a header file and C++ implementation to the hxcpp build xml
	**/
	static function addCApi(headerFile: String, cppFile: String) {
		var classPosInfo = Context.getPosInfos(Context.currentPos());
		var classFilePath = Path.isAbsolute(classPosInfo.file) ? classPosInfo.file : Path.join([Sys.getCwd(), classPosInfo.file]);
		var classDir = Path.directory(classFilePath);

		var buildXml = '
			<copy from="$classDir/$headerFile" to="include" />

			<files id="haxe">
				<file name="$classDir/$cppFile">
					<depend name="$classDir/$headerFile"/>
				</file>
			</files>
		';

		// add @:buildXml
		Context.getLocalClass().get().meta.add(':buildXml', [macro $v{buildXml}], Context.currentPos());

		return Context.getBuildFields();
	}

}

#end