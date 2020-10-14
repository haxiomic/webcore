package webcore.device.native;

import cpp.*;

/**
	See https://developer.apple.com/documentation/corefoundation/cflocale?language=objc#overview
**/
@:include('CoreFoundation/CoreFoundation.h')
extern class CFLocale {

	@:native('CFLocaleCopyPreferredLanguages')
	static function copyPreferredLanguages(): CFArrayRef;

	@:keep
	static inline function preferredLanguagesFirst(): Null<String> {
		var languageCodes = copyPreferredLanguages();
		var languageCodesCount = CFArrayRef.getCount(languageCodes);

		var languageCodeHxStr: String = null;

		// return 'en' by default
		if (languageCodesCount > 0) {
			var cStrPtr: Star<Char> = null;
			untyped __cpp__('
				CFTypeRef languageCodeItem = CFArrayGetValueAtIndex({0}, 0);
				CFStringRef languageCode = reinterpret_cast<CFStringRef>(languageCodeItem);

				// create a c string
				CFIndex cStrBufferLength = CFStringGetMaximumSizeForEncoding(CFStringGetLength(languageCode), kCFStringEncodingUTF8) + 1;
				{1} = (char*) malloc(cStrBufferLength * sizeof(char));

				CFStringGetCString(languageCode, {1}, cStrBufferLength, kCFStringEncodingUTF8);
			', languageCodes, cStrPtr);

			languageCodeHxStr = new String(untyped cStrPtr);

			untyped __cpp__('
				free({0})
			', cStrPtr);
		}

		untyped __cpp__('CFRelease({0})', languageCodes);
		
		return languageCodeHxStr;
	}

}


@:native('CFArrayRef')
extern class CFArrayRef {

	@:native('CFArrayGetCount')
	static function getCount(array: CFArrayRef): Int;

}