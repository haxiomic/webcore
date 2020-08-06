package filesystem.native;

import cpp.*;

/**
	Apple CoreFoundation CFBundle externs
**/
@:include('CoreFoundation/CoreFoundation.h')
extern class CFBundle {

	@:native('CFBundleGetMainBundle')
	static function getMainBundle(): CFBundleRef;

	@:native('CFBundleGetBundleWithIdentifier')
	static function getBundleWithIdentifier(bundleID: CFStringRef): CFBundleRef;

	@:native('CFBundleCopyResourcesDirectoryURL')
	static function copyResourcesDirectoryURL(bundle: CFBundleRef): CFURLRef;

	static inline function getResourceDirectory(bundle: CFBundleRef): String {
		var url = copyResourcesDirectoryURL(bundle);
		var cfPath = CFURLRef.copyPath(url);

		var path = CFStringRef.toHaxeString(cfPath);

		CFStringRef.release(cfPath);
		CFURLRef.release(url);

		return path;
	}

}

@:include('CoreFoundation/CoreFoundation.h')
@:native('CFBundleRef')
extern class CFBundleRef { }

@:include('CoreFoundation/CoreFoundation.h')
@:native('CFStringRef')
extern class CFStringRef {

	static inline function create(str: ConstCharStar): CFStringRef {
		return untyped __cpp__('CFStringCreateWithCString(nullptr, {0}, kCFStringEncodingUTF8)', str);
	}

	static inline function getCStr(cfString: CFStringRef): ConstCharStar {
		return untyped __cpp__('CFStringGetCStringPtr({0}, kCFStringEncodingUTF8)', cfString);
	}

	static inline function toHaxeString(cfString: CFStringRef): String {
		var cStrPtr: Star<Char> = null;
		untyped __cpp__('
			CFIndex cStrBufferLength = CFStringGetMaximumSizeForEncoding(CFStringGetLength({0}), kCFStringEncodingUTF8) + 1;
			{1} = (char*) malloc(cStrBufferLength * sizeof(char));
			CFStringGetCString({0}, {1}, cStrBufferLength, kCFStringEncodingUTF8);
		', cfString, cStrPtr);
		var haxeString = new String(untyped cStrPtr);
		untyped __cpp__('
			free({0})
		', cStrPtr);
		return haxeString;
	}

	@:native('CFRelease')
	static function release(cfString: CFStringRef): Void;

}

@:include('CoreFoundation/CoreFoundation.h')
@:native('CFURLRef')
extern class CFURLRef {

	@:native('CFURLGetString')
	static function getString(url: CFURLRef): CFStringRef;

	@:native('CFURLCopyPath')
	static function copyPath(url: CFURLRef): CFStringRef;

	@:native('CFRelease')
	static function release(url: CFURLRef): Void;

}