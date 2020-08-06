package wc.filesystem;

import haxe.io.Path;

/**
	Read files from the platform's bundle system.

	For example:
	```haxe
	var cancellationToken = File.readBundleFile("songs/theme.mp3", (bytes) => {...});
	```
	
**/
class File {

	#if js
	static final rootDirectory: String = {
		// the asset pack is emitted adjacent to the output js file
		// we determine the location of the js file by reading the src attribute of the script tag it was executed from
		// this must be executed at initialization time
		var scriptSrc = (cast js.Browser.document.currentScript : js.html.ScriptElement).src;
		scriptSrc.substr(0, scriptSrc.lastIndexOf('/'));
	}
	#end

	
	/**
		Read bytes from platform's native file store

		Either one of the callbacks `onComplete` or `onError` will always be called when the file request resolves, including `onError` when the cancellation token is used.
		The onError callback message will always be the string 'canceled' if the cancel token is used before completion.
		If there are no errors then `onProgress` is called at least once before `onComplete`.

		**Implementations**
		- iphoneos: read from local app or framework bundle
		- macos: read from local app or framework bundle
		- android: read from APK resources use AAssetManager
		- web: read a file _relative_ to the compiled .js file (rather than the web page where it is executed)
		- default: read from a directory adjacent to the executable
	**/
	public static function readBundleFile(
		bundleIdentifier: String,
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

			return readFileWeb(rootDirectory + '/' + path, onComplete, onError, onProgress);

		#else
		#if (iphoneos || iphonesim || macos)

			// find path to bundle then use normal stdlib file read
			var bundle = if (bundleIdentifier != null) {
				wc.filesystem.native.CFBundle.getBundleWithIdentifier(filesystem.native.CFBundle.CFStringRef.create(bundleIdentifier));
			} else {
				wc.filesystem.native.CFBundle.getMainBundle();
			}

			if (bundle == null) {
				onError('Could not find bundle with identifier "$bundleIdentifier"');
				return nullCancellationToken;
			}

			var bundleResourceDirectory: String = wc.filesystem.native.CFBundle.getResourceDirectory(bundle);
			var filePath = Path.join([bundleResourceDirectory, path]);

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
			var filePath = Path.join([Sys.programPath(), assetsDirectory, path]);
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