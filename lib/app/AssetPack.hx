package app;

import haxe.io.Path;

#if !macro

/**

	Implement this class to enable embedding and bundling of assets at compile-time

	Use the following metadata to include assets in the generated output:

	**Extending class metadata**
	- `@:embedFile(path: String, ?variableName: String)`
		Embeds a single file into the output

	- `@:copyToBundle(path: String)`
		Copies a file or directory into the app's bundle.	

		For example: a directory can be copied with `@:copyToBundle('../game-assets')` and files in that directory read from the bundle with
		`Assets.readBundleFile('game-assets/theme.mp3', (bytes) -> {...})`.

	**Paths in metadata are evaluated relative to the extending class file path**
	
	For example:
	```
	@:copyToBundle(".../game-files/audio")
	class Songs implements AssetPack { }

	Songs.readFile(Songs.paths.audio.theme_mp3, (bytes) -> {...})
	```

	Paths should be assumed to be case-sensitive, however some platforms will be case-insensitive so you should have filename that differ only by case
	
**/
@:autoBuild(app.AssetPack.AssetPackMacro.build())
interface AssetPack {

}

#else

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Printer;
import haxe.DynamicAccess;

class AssetPackMacro {

	static final isDisplay = Context.defined('display');

	static function build() {
		var localClass = Context.getLocalClass().get();
		var classPosInfo = Context.getPosInfos(Context.currentPos());
		var classFilePath = sys.FileSystem.absolutePath(Context.resolvePath(classPosInfo.file));
		var classDir = Path.directory(classFilePath);
		var fields = Context.getBuildFields();

		var printer = new haxe.macro.Printer();

		var classAssetDirectory = StringTools.replace(printer.printTypePath(app.Macro.classPath(localClass)), '.', '/').toLowerCase();

		var newFields = (macro class X {

			static public final embedded = ${handleEmbedMeta(localClass.meta, classDir)};
			static public final paths = ${handleCopyToBundleMeta('asset-pack/$classAssetDirectory', localClass.meta, classDir)};

			static public inline function readFile(
				path: String,
				?onComplete: (typedarray.ArrayBuffer) -> Void,
				?onError: (String) -> Void,
				?onProgress: (bytesLoaded: Int, bytesTotal: Int) -> Void
			) {
				return filesystem.File.readBundleFile(app.HaxeApp.getBundleIdentifier(), 'asset-pack/' + $v{classAssetDirectory} + '/' + path, onComplete, onError, onProgress);
			}

		}).fields;

		fields = fields.concat(newFields);

		return fields;
	}

	static function handleCopyToBundleMeta(bundleDirectory: String, metaList: MetaAccess, classDir: String) {
		final fileManifestName = 'file-manifest.json';

		var copyMetas = metaList.extract(':copyToBundle');
		var outputDirectory = Path.join([app.Macro.getOutputDirectory(), bundleDirectory]);

		var fileManifestPath = Path.join([outputDirectory, fileManifestName]);

		var existingFileManifest: DynamicAccess<{ctime_ms: Float}> = isDisplay ? {} : try haxe.Json.parse(sys.io.File.getContent(fileManifestPath)) catch (e: Any) {};
		var newFileManifest: DynamicAccess<{ctime_ms: Float}> = {};

		for (meta in copyMetas) {
			switch meta.params[0] {
				case {expr: EConst(CString(path)), pos: pos}:
					// paths are relative to the local class file
					var pathAbsolute = sys.FileSystem.absolutePath(Path.join([classDir, path]));

					function copyFileToBundle(sourcePath: String, targetPathRelativeToOutputDirectory: String) {
						var ctime_ms = isDisplay ? -1 : try sys.FileSystem.stat(sourcePath).ctime.getTime() catch(e: Any) -1;
						// handle as file
						var targetPath = Path.join([outputDirectory, targetPathRelativeToOutputDirectory]);

						var manifestInfo = existingFileManifest.get(targetPathRelativeToOutputDirectory);

						var fileCopyRequired = manifestInfo == null || manifestInfo.ctime_ms != ctime_ms || !sys.FileSystem.exists(targetPath);

						if (fileCopyRequired && !isDisplay) {
							#if debug
							trace('Copying "$path" -> "$targetPath"');
							#end
							var targetDirectory = Path.directory(targetPath);
							app.Macro.touchDirectoryPath(targetDirectory);

							try app.Macro.delete(targetPath) catch (e: Any) {};
							sys.io.File.copy(sourcePath, targetPath);
						}

						newFileManifest.set(targetPathRelativeToOutputDirectory, {ctime_ms: ctime_ms});
					}

					function copyDirectoryToBundle(sourcePath: String, targetPathRelativeToOutputDirectory: String) {
						for (name in sys.FileSystem.readDirectory(sourcePath)) {
							var path = Path.join([sourcePath, name]);
							if (sys.FileSystem.isDirectory(path)) {
								copyDirectoryToBundle(path, Path.join([targetPathRelativeToOutputDirectory, name]));
							} else {
								copyFileToBundle(path, Path.join([targetPathRelativeToOutputDirectory, name]));
							}
						}
					}

					if (sys.FileSystem.isDirectory(pathAbsolute)) {
						copyDirectoryToBundle(pathAbsolute, Path.withoutDirectory(path));
					} else {
						copyFileToBundle(pathAbsolute, Path.withoutDirectory(path));
					}

				case null, _:
					Context.error('@:copyToBundle(path) requires a file path string as an argument', meta.pos);
			}
		}
		
		// delete all files in the old manifest but not in the new one
		if (!isDisplay) {
			for (path in existingFileManifest.keys()) {
				if (!newFileManifest.exists(path)) {
					#if debug
					trace('Deleting "${Path.join([outputDirectory, path])}"');
					#end
					try app.Macro.delete(Path.join([outputDirectory, path])) catch (e: Any) {}
				}
			}

			// write a file manifest
			if (newFileManifest.keys().length > 0) {
				var manifestJson = haxe.Json.stringify(newFileManifest);
				sys.io.File.saveContent(Path.join([outputDirectory, fileManifestName]), manifestJson);
			}
		}

		// create an object that contains all the copied paths
		var allPathsObj: DynamicAccess<Dynamic> = {};

		function getSubObject(obj: DynamicAccess<Dynamic>, path: Array<String>): DynamicAccess<Dynamic> {
			var first = path[0];
			var remaining = path.slice(1);
			if (first == "") {
				return obj;
			}
			var fieldName = safeVariableName(first);
			var subObj = obj.get(fieldName);
			if (subObj == null) {
				subObj = {};
				obj.set(fieldName, subObj);
			}
			return remaining.length > 0 ? getSubObject(subObj, remaining) : subObj;
		}

		// add all paths
		for (filePath in newFileManifest.keys()) {
			var directories = Path.directory(filePath).split('/');
			var directoryObj = getSubObject(allPathsObj, directories);
			var filename = Path.withoutDirectory(filePath);
			var fieldName = safeVariableName(filename);
			directoryObj.set(fieldName, filePath);
		}

		return macro $v{allPathsObj};
	}

	static function handleEmbedMeta(metaList: MetaAccess, classDir: String) {
		var objectFields = new Array<ObjectField>();
		
		// metadata to embed a single file
		var embedMetas = metaList.extract(':embedFile');

		for (embedMeta in embedMetas) {
			switch embedMeta.params[0] {
				case {expr: EConst(CString(path)), pos: pos}:
					// paths are relative to the local class file
					var absPath = sys.FileSystem.absolutePath(Path.join([classDir, path]));
					var filename = Path.withoutDirectory(path);

					// we have to use cleaned variable names because haxe doesn't yet support obj."field-name"
					var variableName = safeVariableName(
						switch embedMeta.params[1] {
							case {expr: EConst(CString(name)) }: name;
							case null, _: filename;
						}
					);

					var resourceId = path;

					if (!isDisplay) {
						var fileBytes = try sys.io.File.getBytes(absPath) catch (e: Any) {
							Context.fatalError('Failed to embed file: $e', pos);
						}

						// embed bytes using the haxe resource system
						Context.addResource(resourceId, fileBytes);
					}

					objectFields.push({
						field: variableName,
						expr: isDisplay ? macro new typedarray.ArrayBuffer(0) : macro (haxe.Resource.getBytes($v{resourceId}): typedarray.ArrayBuffer)
					});

				case null, _:
					Context.error('@:embedFile(path, ?variableName) requires a file path string as an argument', embedMeta.pos);
			}
		}

		return {
			pos: Context.currentPos(),
			expr: EObjectDecl(objectFields)
		}
	}

	static function safeVariableName(str: String) {
		// replace non-ascii characters with '_'
		var wordCharacters = ~/[^\w]/g.replace(str, '_');
		// make sure it starts with a-z
		if (!~/[a-z]/i.match(wordCharacters.charAt(0))) {
			wordCharacters = '_' + wordCharacters;
		}
		return wordCharacters;
	}

}

#end