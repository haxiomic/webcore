#if !macro

/**
	Expose a C++ interface for the component in the generated hxcpp C++
	
	Methods exposed on an instance of the component are defined in IMinimalGL 
**/

@:nativeGen
@:structAccess
@:build(NativeAPI.Macro.addBuildXml())
class NativeAPI {

	@:keep static public function create(width: Int, height: Int): IMinimalGL {
		var glContext = new gluon.es2.impl.ES2Context();
		return new MinimalGL(glContext, width, height);
	}

}

#else

import haxe.macro.Context;
import haxe.io.Path;

class Macro {

	static function addBuildXml() {
		var classPosInfo = Context.getPosInfos(Context.currentPos());
		var classFilePath = Path.isAbsolute(classPosInfo.file) ? classPosInfo.file : Path.join([Sys.getCwd(), classPosInfo.file]);
		var classDir = Path.directory(classFilePath);

		var buildXml = '
			<copy from="$classDir/MinimalGL.h" to="include" />

			<files id="haxe">
				<file name="$classDir/MinimalGL.cpp">
					<depend name="$classDir/MinimalGL.h"/>
				</file>
			</files>
		';
		
		// add @:buildXml
		Context.getLocalClass().get().meta.add(':buildXml', [macro $v{buildXml}], Context.currentPos());

		return Context.getBuildFields();
	}

}

#end