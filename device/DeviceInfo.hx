package device;

class DeviceInfo {

	/**
		Returns a two letter [ISO 639-1 code](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) for the device's preferred language setting
		For example: 'en' - English, 'de' - German

		Returns null if this information is unavailable
	**/
	static public function getSystemLanguageIsoCode(): Null<String> {
		#if js
		return js.Browser.navigator.language.substr(0, 2);
		#else
		#if (iphoneos || iphonesim || macos)

		return device.native.CFLocale.preferredLanguagesFirst();

		#else

		return null;

		#end
		#end
	}

}