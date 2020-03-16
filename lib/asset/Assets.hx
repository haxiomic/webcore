package asset;

import haxe.io.Path;


#if !macro

/**
	Read files from the platform's bundle system.

	For example:
	```haxe
	var cancellationToken = Assets.readBundleFile("asset-bundle", "songs/theme.mp3", (bytes) => {...});
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

	- `@:bundleName(name: String)`
		Overrides the bundle name. By default, the bundle name is the same as the class name

	**Paths in metadata are evaluated relative to the extending class file path**
	
	For example:
	```
	@:copyToBundle(".../game-files/songs")
	class Songs extends asset.Assets { }

	Songs.readBundleFile(Songs.bundlePaths.songs.theme_mp3, (bytes) -> {...})
	```
	
**/
@:autoBuild(asset.Assets.Macro.build())
class Assets {
	
	/**
		Read bytes from platform's native file store

		Either one of the callbacks `onComplete` or `onError` will always be called when the file request resolves, including `onError` when the cancellation token is used.

		**Implementations**
		- iOS: read file from mainBundle
		- Android: read file from APK assets using the AssetManager
		- Desktop: read file relative to executable
		- Web: read file relative to current page path
	**/
	public static function readBundleFile(
		bundleName: String,
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
			var filePath = '$bundleName/$path'; // avoid Path.join on web to keep output smaller
			return readFileWeb(filePath, onComplete, onError, onProgress);
		#else
		#if (iphoneos || iphonesim)

		#else
		// local file read
		#end
		#end

		// @! remove
		return nullCancellationToken;
	}

	static inline function readFileStdLib(
		bundleName: String,
		path: String,
		onComplete: (typedarray.ArrayBuffer) -> Void,
		onError: (String) -> Void,
		onProgress: (bytesLoaded: Int, bytesTotal: Int) -> Void
	): {
		cancel: () -> Void,
	} {
		// should we spawn a thread?
		// NSData *fileData = [NSData dataWithContentsOfURL:fileUrl];
		// C-level api
		// https://stackoverflow.com/questions/18436311/how-to-get-byte-data-from-file-in-object-c
		// maybe fopen will work
		// that way we can reuse code between iOS and android ~~ actually this doesn't work for android and we need to use AAssetManager https://stackoverflow.com/questions/18090483/fopen-fread-apk-assets-from-nativeactivity-on-android
		//		https://stackoverflow.com/questions/23372819/android-ndk-read-file-from-assets-inside-of-shared-library
		// https://stackoverflow.com/questions/26746062/open-file-in-bundle-using-fopen
		// that impiles the haxe std lib might work since that uses fopen (File.cpp:355)

		// in android _maaaybe_ we can use hx stdlib zip
		// http://www.anddev.org/ndk_opengl_-_loading_resources_and_assets_from_native_code-t11978.html
		// https://stackoverflow.com/questions/13827639/accessing-a-compressed-file-in-an-apk-from-native-code-read-a-zip-from-inside-a
		return null;
	}

	#if js
	static inline function readFileWeb(
		filePath: String,
		onComplete: (typedarray.ArrayBuffer) -> Void,
		onError: (String) -> Void,
		onProgress: (bytesLoaded: Int, bytesTotal: Int) -> Void
	): {
		cancel: () -> Void,
	} {
		// we use XMLHttpRequest because fetch doesn't yet have reliably available aborting
		var req = new js.html.XMLHttpRequest();
		req.open('GET', filePath, true);
		req.responseType = ARRAYBUFFER;
		req.onloadend = (e) -> switch req.status {
			case 0: // aborted
				onError('HTTP request ended with no status. This indicates the request was aborted');
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
		req.onprogress = (e) -> if (req.status >= 200 && req.status < 300 && e.lengthComputable) {
			onProgress(e.loaded, e.total);
		}
		req.send();

		return {
			cancel: () -> req.abort()
		}
	}
	#end

}

#else

import haxe.macro.Context;

class Macro {

	static function build() {
		var localClass = Context.getLocalClass().get();
		var classPosInfo = Context.getPosInfos(Context.currentPos());
		var classFilePath = sys.FileSystem.absolutePath(Context.resolvePath(classPosInfo.file));
		var classDir = Path.directory(classFilePath);
		var fields = Context.getBuildFields();
		var metas = localClass.meta;

		// @! we have to use cleaned variable names because haxe doesn't yet support obj."field-name"

		// metadata to embed a single file
		var embedMetas = metas.extract(':embedFile').concat(metas.extract('embedFile'));

		for (embedMeta in embedMetas) {
			switch embedMeta.params[0] {
				case {expr: EConst(CString(path)), pos: pos}:
					// paths are relative to this file
					var absPath = sys.FileSystem.absolutePath(Path.join([classDir, path]));

					var filename = Path.withoutDirectory(path);

					var variableName = safeVariableName(
						switch embedMeta.params[1] {
							case {expr: EConst(CString(name)) }: name;
							case null, _: filename;
						}
					);

					var resourceId = path;

					#if !display
					var fileBytes = try sys.io.File.getBytes(absPath) catch (e: Any) {
						Context.fatalError('Failed to embed file: $e', pos);
					}

					// embed bytes using the haxe resource system
					Context.addResource(resourceId, fileBytes);
					#end

					var newFields = (macro class X {

						static public final $variableName: typedarray.ArrayBuffer =
							#if !display
								haxe.Resource.getBytes($v{resourceId});
							#else
								new haxe.io.Bytes(0);
							#end

					}).fields;

					fields = fields.concat(newFields);

				case null, _:
					Context.error('@embedFile requires a file path string as an argument', embedMeta.pos);
			}
		}

		return fields;
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