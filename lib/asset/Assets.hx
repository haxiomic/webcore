package asset;

import haxe.io.Path;

#if !macro

/**
	Read files from the platform's bundle system.

	For example:
	```haxe
	var cancellationToken = Assets.readBundleFile("songs/theme.mp3", (bytes) => {...});
	```

	Paths should be assumed to be case-sensitive, however some platforms will be case-insensitive so you should have filename that differ only by case

	To include files in the a bundle generated alongside the compiler output, extend this class and use the following metadata:

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
	class Songs extends asset.Assets { }

	Songs.readBundleFile(Songs.paths.audio.theme_mp3, (bytes) -> {...})
	```
	
**/
@:autoBuild(asset.Assets.Macro.build())
class Assets {

	/**
		If the platform uses a bundle system (iOS, macOS), this variables sets the bundle identifer to find assets in
	**/
	static public var bundleIdentifier: String = null;
	static public var assetsDirectory = 'assets';
	
	/**
		Read bytes from platform's native file store

		Either one of the callbacks `onComplete` or `onError` will always be called when the file request resolves, including `onError` when the cancellation token is used.
		The onError callback message will always be the string 'canceled' if the cancel token is used before completion.
		If there are no errors then `onProgress` is called at least once before `onComplete`.

		**Implementations**
		- iphoneos: read from local app or framework bundle
		- macos: read from local app or framework bundle
		- default: read from a directory called 'assets' adjacent to the executable
		- android: read from APK resources use AAssetManager
	**/
	public static function readBundleFile(
		path: String,
		?onComplete: (typedarray.ArrayBuffer) -> Void,
		?onError: (String) -> Void,
		?onProgress: (bytesLoaded: Int, bytesTotal: Int) -> Void
	): {
		cancel: () -> Void,
	} {
		if (onComplete == null) onComplete = (_) -> {};
		if (onError == null) onError = (_) -> {};
		if (onProgress == null) onProgress = (_, _) -> {};

		var nullCancellationToken = {
			cancel: () -> {}
		}

		if (path == null) {
			onError("Cannot use a value of null for the filePath");
			return nullCancellationToken;
		}

		#if js

			var filePath = '$assetsDirectory/$path'; // avoid Path.join on web to keep output smaller
			return readFileWeb(filePath, onComplete, onError, onProgress);

		#else
		#if (iphoneos || iphonesim || macos)

			// find path to bundle then use normal stdlib file read
			var bundle = if (bundleIdentifier != null) {
				asset.native.CFBundle.getBundleWithIdentifier(asset.native.CFBundle.CFStringRef.create(bundleIdentifier));
			} else {
				asset.native.CFBundle.getMainBundle();
			}

			if (bundle == null) {
				onError('Could not find bundle with identifier "$bundleIdentifier"');
				return nullCancellationToken;
			}

			var url = asset.native.CFBundle.copyResourcesDirectoryURL(bundle);
			var bundleResourceDirectory: String = asset.native.CFBundle.CFStringRef.getCStr(asset.native.CFBundle.CFURLRef.copyPath(url));
			var filePath = Path.join([bundleResourceDirectory, assetsDirectory, path]);

			return readFileStdLib(filePath, onComplete, onError, onProgress);

		#elseif android
			// in android _maaaybe_ we can use hx stdlib zip
			// http://www.anddev.org/ndk_opengl_-_loading_resources_and_assets_from_native_code-t11978.html
			// https://stackoverflow.com/questions/13827639/accessing-a-compressed-file-in-an-apk-from-native-code-read-a-zip-from-inside-a
			// but best thing is probably AAssetManager externs
			// https://stackoverflow.com/questions/18090483/fopen-fread-apk-assets-from-nativeactivity-on-android
			// https://stackoverflow.com/questions/23372819/android-ndk-read-file-from-assets-inside-of-shared-library
			return nullCancellationToken;
		#else
	
			// local file read
			var filePath = Path.join([Sys.executablePath(), assetsDirectory, path]);
			return readFileStdLib(filePath, onComplete, onError, onProgress);

		#end
		#end
	}

	#if cpp
	static inline function readFileStdLib(
		filePath: String,
		onComplete: (typedarray.ArrayBuffer) -> Void,
		onError: (String) -> Void,
		onProgress: (bytesLoaded: Int, bytesTotal: Int) -> Void
	): {
		cancel: () -> Void,
	} {
		var threadHandle = sys.thread.Thread.create(() -> {
			try {
				if (sys.thread.Thread.readMessage(false) == 'cancel') {
					haxe.EntryPoint.runInMainThread(() -> onError('canceled'));
					return;
				}

				// we could split the read into chunks to enable canceling during load
				var bytes = sys.io.File.getBytes(filePath);

				// if canceled during load, check after to prevent onComplete firing
				if (sys.thread.Thread.readMessage(false) == 'cancel') {
					haxe.EntryPoint.runInMainThread(() -> onError('canceled'));
					return;
				}

				haxe.EntryPoint.runInMainThread(() -> {
					onProgress(bytes.length, bytes.length);
					onComplete(bytes);
				});
			} catch (e: Any) {
				haxe.EntryPoint.runInMainThread(() -> onError(e));
			}
		});
		return {
			cancel: () -> threadHandle.sendMessage('cancel'),
		};
	}
	#end

	#if js
	static inline function readFileWeb(
		filePath: String,
		onComplete: (typedarray.ArrayBuffer) -> Void,
		onError: (String) -> Void,
		onProgress: (bytesLoaded: Int, bytesTotal: Int) -> Void
	): {
		cancel: () -> Void,
	} {
		var userCanceled = false;
		// we use XMLHttpRequest because fetch doesn't yet have reliably available aborting
		var req = new js.html.XMLHttpRequest();
		req.open('GET', filePath, true);
		req.responseType = ARRAYBUFFER;
		req.onloadend = (e) -> {
			if (userCanceled) {
				onError('canceled');
				return;
			}
			switch req.status {
				case 0: // aborted
					onError('HTTP request ended with no status. This may indicate the request was aborted');
				case code if (code >= 200 && code < 300):
					// success generally, check response type
					if (req.response != null && js.Syntax.instanceof(req.response, js.lib.ArrayBuffer)) {
						onComplete((req.response: js.lib.ArrayBuffer));
					} else {
						onError('HTTP request was successful but response was not an ArrayBuffer. HTTP status: ${req.statusText} (${req.status})');
					}
				default:
					onError('HTTP request ended with status: ${req.statusText} (${req.status})');
			}
		}
		req.onprogress = (e) -> if (req.status >= 200 && req.status < 300 && e.lengthComputable) {
			onProgress(e.loaded, e.total);
		}
		req.send();

		return {
			cancel: () -> {
				userCanceled = true;
				req.abort();
			}
		}
	}
	#end

}

#else

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Printer;
import haxe.DynamicAccess;

class Macro {

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
			static public final paths = ${handleCopyToBundleMeta('assets/$classAssetDirectory', localClass.meta, classDir)};

			static public inline function readFile(
				path: String,
				?onComplete: (typedarray.ArrayBuffer) -> Void,
				?onError: (String) -> Void,
				?onProgress: (bytesLoaded: Int, bytesTotal: Int) -> Void
			) {
				return asset.Assets.readBundleFile(path, onComplete, onError, onProgress);
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
							app.Macro.copyToDirectory(sourcePath, targetDirectory, true);
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