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

}

@:native('CFBundleRef')
extern class CFBundleRef { }

@:native('CFStringRef')
extern class CFStringRef {

	static inline function create(str: ConstCharStar): CFStringRef {
		return untyped __cpp__('CFStringCreateWithCString(nullptr, {0}, kCFStringEncodingUTF8)', str);
	}

	static inline function getCStr(cfString: CFStringRef): ConstCharStar {
		return untyped __cpp__('CFStringGetCStringPtr({0}, kCFStringEncodingUTF8)', cfString);
	}

}

@:native('CFURLRef')
extern class CFURLRef {

	@:native('CFURLGetString')
	static function getString(url: CFURLRef): CFStringRef;

	@:native('CFURLCopyPath')
	static function copyPath(url: CFURLRef): CFStringRef;

}