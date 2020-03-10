/**
	Externs for David Reid's (dr-soft) miniaudio.h
	
	@version miniaudio.h v0.9.9, commit #1916f3
	@author George Corney (haxiomic)
**/
package audio.native;

import cpp.*;

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
extern class MiniAudio {

	@:native('ma_get_bytes_per_sample')
	static function get_bytes_per_sample(format: Format): UInt32;

	@:native('ma_get_bytes_per_frame')
	static function get_bytes_per_frame(format: Format, channels: UInt32): UInt32;

}

/*
	MINIADUIO Primitive Data Types
*/

abstract MaBool32(UInt32) to UInt32 from UInt32 {

	@:to inline function toBool(): Bool {
		return cast this;
	}

	@:from static inline function fromBool(b: Bool) {
		return cast b;
	}

}

/*
	MINIAUDIO Enums
*/
@:notNull extern enum abstract Backend(MaBackend) {
	@:native('ma_backend_wasapi') var WASAPI;
	@:native('ma_backend_dsound') var DSOUND;
	@:native('ma_backend_winmm') var WINMM;
	@:native('ma_backend_coreaudio') var COREAUDIO;
	@:native('ma_backend_sndio') var SNDIO;
	@:native('ma_backend_audio4') var AUDIO4;
	@:native('ma_backend_oss') var OSS;
	@:native('ma_backend_pulseaudio') var PULSEAUDIO;
	@:native('ma_backend_alsa') var ALSA;
	@:native('ma_backend_jack') var JACK;
	@:native('ma_backend_aaudio') var AAUDIO;
	@:native('ma_backend_opensl') var OPENSL;
	@:native('ma_backend_webaudio') var WEBAUDIO;
	@:native('ma_backend_null') var NULL;

	inline function toString(): String {
		var name: ConstCharStar = untyped __global__.ma_get_backend_name(this);
		return name.toString();
	}
}
@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:unreflective @:native('ma_backend')
private extern class MaBackend {}

@:notNull extern enum abstract ThreadPriority(MaThreadPriority) {
	@:native('ma_thread_priority_idle') var IDLE;
	@:native('ma_thread_priority_lowest') var LOWEST;
	@:native('ma_thread_priority_low') var LOW;
	@:native('ma_thread_priority_normal') var NORMAL;
	@:native('ma_thread_priority_high') var HIGH;
	@:native('ma_thread_priority_highest') var HIGHEST;
	@:native('ma_thread_priority_realtime') var REALTIME;
	@:native('ma_thread_priority_default') var DEFAULT;
	@:to inline function toInt(): Int return cast this;
	@:from static inline function fromInt(i: Int): ThreadPriority return cast i;
}
@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('ma_thread_priority') @:unreflective 
private extern class MaThreadPriority {}

@:notNull extern enum abstract Format(MaFormat){
	/*
	I like to keep these explicitly defined because they're used as a key into a lookup table. When items are
	added to this, make sure there are no gaps and that they're added to the lookup table in ma_get_bytes_per_sample().
	*/
	@:native('ma_format_unknown') var UNKNOWN; /* Mainly used for indicating an error, but also used as the default for the output format for decoders. */
	@:native('ma_format_u8') var U8;     
	@:native('ma_format_s16') var S16; /* Seems to be the most widely supported format. */
	@:native('ma_format_s24') var S24; /* Tightly packed. 3 bytes per sample. */
	@:native('ma_format_s32') var S32;    
	@:native('ma_format_f32') var F32;    
	@:native('ma_format_count') var COUNT;

	inline function toString(): String {
		var name: ConstCharStar = untyped __global__.ma_get_format_name(this);
		return name.toString();
	}
}
@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('ma_format') @:unreflective
private extern class MaFormat {}

@:notNull extern enum abstract DeviceType(MaDeviceType) {
	@:native('ma_device_type_playback') var PLAYBACK;
	@:native('ma_device_type_capture') var CAPTURE;
	@:native('ma_device_type_duplex') var DUPLEX;
	@:native('ma_device_type_loopback') var LOOPBACK;
}
@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('ma_device_type') @:unreflective
private extern class MaDeviceType {}

@:notNull extern enum abstract PerformanceProfile(MaPerformanceProfile) {
	@:native('ma_performance_profile_low_latency') var LOW_LATENCY;
	@:native('ma_performance_profile_conservative') var CONSERVATIVE;
}
@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('ma_performance_profile') @:unreflective
private extern class MaPerformanceProfile {}

@:notNull extern enum abstract ShareMode(MaShareMode) {
	@:native('ma_share_mode_shared') var SHARED;
	@:native('ma_share_mode_exclusive') var EXCLUSIVE;
}
@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('ma_share_mode') @:unreflective
private extern class MaShareMode {}

@:notNull extern enum abstract SeekOrigin(MaSeekOrigin) {
	@:native('ma_seek_origin_start') var START;
	@:native('ma_seek_origin_current') var CURRENT;
	@:to inline function toInt(): Int return cast this;
}
@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('ma_seek_origin') @:unreflective
private extern class MaSeekOrigin {}

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:notNull extern enum abstract Result(MaResult) {
	@:native('MA_SUCCESS') var SUCCESS;
	@:native('MA_ERROR') var ERROR;
	@:native('MA_INVALID_ARGS') var INVALID_ARGS;
	@:native('MA_INVALID_OPERATION') var INVALID_OPERATION;
	@:native('MA_OUT_OF_MEMORY') var OUT_OF_MEMORY;
	@:native('MA_ACCESS_DENIED') var ACCESS_DENIED;
	@:native('MA_TOO_LARGE') var TOO_LARGE;
	@:native('MA_TIMEOUT') var TIMEOUT;
	@:native('MA_FORMAT_NOT_SUPPORTED') var FORMAT_NOT_SUPPORTED;
	@:native('MA_DEVICE_TYPE_NOT_SUPPORTED') var DEVICE_TYPE_NOT_SUPPORTED;
	@:native('MA_SHARE_MODE_NOT_SUPPORTED') var SHARE_MODE_NOT_SUPPORTED;
	@:native('MA_NO_BACKEND') var NO_BACKEND;
	@:native('MA_NO_DEVICE') var NO_DEVICE;
	@:native('MA_API_NOT_FOUND') var API_NOT_FOUND;
	@:native('MA_INVALID_DEVICE_CONFIG') var INVALID_DEVICE_CONFIG;
	@:native('MA_DEVICE_BUSY') var DEVICE_BUSY;
	@:native('MA_DEVICE_NOT_INITIALIZED') var DEVICE_NOT_INITIALIZED;
	@:native('MA_DEVICE_NOT_STARTED') var DEVICE_NOT_STARTED;
	@:native('MA_DEVICE_UNAVAILABLE') var DEVICE_UNAVAILABLE;
	@:native('MA_FAILED_TO_MAP_DEVICE_BUFFER') var FAILED_TO_MAP_DEVICE_BUFFER;
	@:native('MA_FAILED_TO_UNMAP_DEVICE_BUFFER') var FAILED_TO_UNMAP_DEVICE_BUFFER;
	@:native('MA_FAILED_TO_INIT_BACKEND') var FAILED_TO_INIT_BACKEND;
	@:native('MA_FAILED_TO_READ_DATA_FROM_CLIENT') var FAILED_TO_READ_DATA_FROM_CLIENT;
	@:native('MA_FAILED_TO_READ_DATA_FROM_DEVICE') var FAILED_TO_READ_DATA_FROM_DEVICE;
	@:native('MA_FAILED_TO_SEND_DATA_TO_CLIENT') var FAILED_TO_SEND_DATA_TO_CLIENT;
	@:native('MA_FAILED_TO_SEND_DATA_TO_DEVICE') var FAILED_TO_SEND_DATA_TO_DEVICE;
	@:native('MA_FAILED_TO_OPEN_BACKEND_DEVICE') var FAILED_TO_OPEN_BACKEND_DEVICE;
	@:native('MA_FAILED_TO_START_BACKEND_DEVICE') var FAILED_TO_START_BACKEND_DEVICE;
	@:native('MA_FAILED_TO_STOP_BACKEND_DEVICE') var FAILED_TO_STOP_BACKEND_DEVICE;
	@:native('MA_FAILED_TO_CONFIGURE_BACKEND_DEVICE') var FAILED_TO_CONFIGURE_BACKEND_DEVICE;
	@:native('MA_FAILED_TO_CREATE_MUTEX') var FAILED_TO_CREATE_MUTEX;
	@:native('MA_FAILED_TO_CREATE_EVENT') var FAILED_TO_CREATE_EVENT;
	@:native('MA_FAILED_TO_CREATE_SEMAPHORE') var FAILED_TO_CREATE_SEMAPHORE;
	@:native('MA_FAILED_TO_CREATE_THREAD') var FAILED_TO_CREATE_THREAD;

	@:to inline function toInt(): Int return cast this;

	inline function toString(): String {
		return ResultLookup.getString(cast this);
	}
}
@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('int') @:unreflective
private extern class MaResult {}

class ResultLookup {
	static final strings: Map<Int, String> = [
		SUCCESS => 'SUCCESS',
		ERROR => 'ERROR',
		INVALID_ARGS => 'INVALID_ARGS',
		INVALID_OPERATION => 'INVALID_OPERATION',
		OUT_OF_MEMORY => 'OUT_OF_MEMORY',
		ACCESS_DENIED => 'ACCESS_DENIED',
		TOO_LARGE => 'TOO_LARGE',
		TIMEOUT => 'TIMEOUT',
		FORMAT_NOT_SUPPORTED => 'FORMAT_NOT_SUPPORTED',
		DEVICE_TYPE_NOT_SUPPORTED => 'DEVICE_TYPE_NOT_SUPPORTED',
		SHARE_MODE_NOT_SUPPORTED => 'SHARE_MODE_NOT_SUPPORTED',
		NO_BACKEND => 'NO_BACKEND',
		NO_DEVICE => 'NO_DEVICE',
		API_NOT_FOUND => 'API_NOT_FOUND',
		INVALID_DEVICE_CONFIG => 'INVALID_DEVICE_CONFIG',
		DEVICE_BUSY => 'DEVICE_BUSY',
		DEVICE_NOT_INITIALIZED => 'DEVICE_NOT_INITIALIZED',
		DEVICE_NOT_STARTED => 'DEVICE_NOT_STARTED',
		DEVICE_UNAVAILABLE => 'DEVICE_UNAVAILABLE',
		FAILED_TO_MAP_DEVICE_BUFFER => 'FAILED_TO_MAP_DEVICE_BUFFER',
		FAILED_TO_UNMAP_DEVICE_BUFFER => 'FAILED_TO_UNMAP_DEVICE_BUFFER',
		FAILED_TO_INIT_BACKEND => 'FAILED_TO_INIT_BACKEND',
		FAILED_TO_READ_DATA_FROM_CLIENT => 'FAILED_TO_READ_DATA_FROM_CLIENT',
		FAILED_TO_READ_DATA_FROM_DEVICE => 'FAILED_TO_READ_DATA_FROM_DEVICE',
		FAILED_TO_SEND_DATA_TO_CLIENT => 'FAILED_TO_SEND_DATA_TO_CLIENT',
		FAILED_TO_SEND_DATA_TO_DEVICE => 'FAILED_TO_SEND_DATA_TO_DEVICE',
		FAILED_TO_OPEN_BACKEND_DEVICE => 'FAILED_TO_OPEN_BACKEND_DEVICE',
		FAILED_TO_START_BACKEND_DEVICE => 'FAILED_TO_START_BACKEND_DEVICE',
		FAILED_TO_STOP_BACKEND_DEVICE => 'FAILED_TO_STOP_BACKEND_DEVICE',
		FAILED_TO_CONFIGURE_BACKEND_DEVICE => 'FAILED_TO_CONFIGURE_BACKEND_DEVICE',
		FAILED_TO_CREATE_MUTEX => 'FAILED_TO_CREATE_MUTEX',
		FAILED_TO_CREATE_EVENT => 'FAILED_TO_CREATE_EVENT',
		FAILED_TO_CREATE_SEMAPHORE => 'FAILED_TO_CREATE_SEMAPHORE',
		FAILED_TO_CREATE_THREAD => 'FAILED_TO_CREATE_THREAD',
	];

	static public function getString(result: Result) {
		var str = strings[result];
		return str == null ? '<unknown>' : str;
	}
}

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:notNull extern enum abstract Channel(MaChannel) {

	@:native('MA_CHANNEL_NONE') var NONE;
	@:native('MA_CHANNEL_MONO') var MONO;
	@:native('MA_CHANNEL_FRONT_LEFT') var FRONT_LEFT;
	@:native('MA_CHANNEL_FRONT_RIGHT') var FRONT_RIGHT;
	@:native('MA_CHANNEL_FRONT_CENTER') var FRONT_CENTER;
	@:native('MA_CHANNEL_LFE') var LFE;
	@:native('MA_CHANNEL_BACK_LEFT') var BACK_LEFT;
	@:native('MA_CHANNEL_BACK_RIGHT') var BACK_RIGHT;
	@:native('MA_CHANNEL_FRONT_LEFT_CENTER') var FRONT_LEFT_CENTER;
	@:native('MA_CHANNEL_FRONT_RIGHT_CENTER') var FRONT_RIGHT_CENTER;
	@:native('MA_CHANNEL_BACK_CENTER') var BACK_CENTER;
	@:native('MA_CHANNEL_SIDE_LEFT') var SIDE_LEFT;
	@:native('MA_CHANNEL_SIDE_RIGHT') var SIDE_RIGHT;
	@:native('MA_CHANNEL_TOP_CENTER') var TOP_CENTER;
	@:native('MA_CHANNEL_TOP_FRONT_LEFT') var TOP_FRONT_LEFT;
	@:native('MA_CHANNEL_TOP_FRONT_CENTER') var TOP_FRONT_CENTER;
	@:native('MA_CHANNEL_TOP_FRONT_RIGHT') var TOP_FRONT_RIGHT;
	@:native('MA_CHANNEL_TOP_BACK_LEFT') var TOP_BACK_LEFT;
	@:native('MA_CHANNEL_TOP_BACK_CENTER') var TOP_BACK_CENTER;
	@:native('MA_CHANNEL_TOP_BACK_RIGHT') var TOP_BACK_RIGHT;
	@:native('MA_CHANNEL_AUX_0') var AUX_0;
	@:native('MA_CHANNEL_AUX_1') var AUX_1;
	@:native('MA_CHANNEL_AUX_2') var AUX_2;
	@:native('MA_CHANNEL_AUX_3') var AUX_3;
	@:native('MA_CHANNEL_AUX_4') var AUX_4;
	@:native('MA_CHANNEL_AUX_5') var AUX_5;
	@:native('MA_CHANNEL_AUX_6') var AUX_6;
	@:native('MA_CHANNEL_AUX_7') var AUX_7;
	@:native('MA_CHANNEL_AUX_8') var AUX_8;
	@:native('MA_CHANNEL_AUX_9') var AUX_9;
	@:native('MA_CHANNEL_AUX_10') var AUX_10;
	@:native('MA_CHANNEL_AUX_11') var AUX_11;
	@:native('MA_CHANNEL_AUX_12') var AUX_12;
	@:native('MA_CHANNEL_AUX_13') var AUX_13;
	@:native('MA_CHANNEL_AUX_14') var AUX_14;
	@:native('MA_CHANNEL_AUX_15') var AUX_15;
	@:native('MA_CHANNEL_AUX_16') var AUX_16;
	@:native('MA_CHANNEL_AUX_17') var AUX_17;
	@:native('MA_CHANNEL_AUX_18') var AUX_18;
	@:native('MA_CHANNEL_AUX_19') var AUX_19;
	@:native('MA_CHANNEL_AUX_20') var AUX_20;
	@:native('MA_CHANNEL_AUX_21') var AUX_21;
	@:native('MA_CHANNEL_AUX_22') var AUX_22;
	@:native('MA_CHANNEL_AUX_23') var AUX_23;
	@:native('MA_CHANNEL_AUX_24') var AUX_24;
	@:native('MA_CHANNEL_AUX_25') var AUX_25;
	@:native('MA_CHANNEL_AUX_26') var AUX_26;
	@:native('MA_CHANNEL_AUX_27') var AUX_27;
	@:native('MA_CHANNEL_AUX_28') var AUX_28;
	@:native('MA_CHANNEL_AUX_29') var AUX_29;
	@:native('MA_CHANNEL_AUX_30') var AUX_30;
	@:native('MA_CHANNEL_AUX_31') var AUX_31;
	@:native('MA_CHANNEL_LEFT') var LEFT;
	@:native('MA_CHANNEL_RIGHT') var RIGHT;

}
@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('ma_uint8') @:unreflective
private extern class MaChannel {}

/*
	MINIAUDIO Classes
*/

typedef ContextLogCallback = Callable<(Star<Context>, Star<Device>, logLevel: UInt32, message: ConstCharStar) -> Void>;

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('ma_context_config') @:unreflective
@:structAccess
extern class ContextConfig {
	var threadPriority: ThreadPriority;
	var pUserData: Star<cpp.Void>;
	var logCallback: ContextLogCallback;

	@:native('ma_context_config_init')
	static function init(): ContextConfig;
}

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('ma_context') @:unreflective
@:structAccess
extern class Context {

	var backend: Backend;
	var logCallback: ContextLogCallback;
	var threadPriority: ThreadPriority;
	var pUserData: Star<cpp.Void>;
	var deviceEnumLock: Mutex; /* Used to make ma_context_get_devices() thread safe. */
	var deviceInfoLock: Mutex; /* Used to make ma_context_get_device_info() thread safe. */
	var deviceInfoCapacity: UInt32; /* Total capacity of pDeviceInfos. */
	var playbackDeviceInfoCount: UInt32;
	var captureDeviceInfoCount: UInt32;
	// var pDeviceInfos: Star<DeviceInfo>; /* Playback devices first, then capture. */
	var isBackendAsynchronous: Bool; /* Set when the context is initialized. Set to 1 for asynchronous backends such as Core Audio and JACK. Do not modify. */

	// ma_result (* onUninit        )(ma_context* pContext);
	// ma_bool32 (* onDeviceIDEqual )(ma_context* pContext, const ma_device_id* pID0, const ma_device_id* pID1);
	// ma_result (* onEnumDevices   )(ma_context* pContext, ma_enum_devices_callback_proc callback, void* pUserData); /* Return false from the callback to stop enumeration. */
	// ma_result (* onGetDeviceInfo )(ma_context* pContext, ma_device_type deviceType, const ma_device_id* pDeviceID, ma_share_mode shareMode, ma_device_info* pDeviceInfo);
	// ma_result (* onDeviceInit    )(ma_context* pContext, const ma_device_config* pConfig, ma_device* pDevice);
	// void      (* onDeviceUninit  )(ma_device* pDevice);
	// ma_result (* onDeviceStart   )(ma_device* pDevice);
	// ma_result (* onDeviceStop    )(ma_device* pDevice);
	// ma_result (* onDeviceMainLoop)(ma_device* pDevice);

	inline function init(?backends: Array<Backend>, config: Star<ContextConfig>): Result {
		var backendCount = backends != null ? backends.length : 0;
		var backendsPointer = backends == null ? null : NativeArray.address(backends, 0);
		return untyped __global__.ma_context_init(backendsPointer, backendCount, config, (context: Star<Context>));
	}

	inline function uninit(): Result {
		return untyped __global__.ma_context_uninit((this: Star<Context>));
	}

	@:native('~ma_context')
	function free(): Void;

	@:native('new ma_context')
	static function alloc(): Star<Context>;

}

@:structAccess
@:unreflective
extern class PlaybackInfo {
	//     char name[256]; /* Maybe temporary. Likely to be replaced with a query API. */
	//     ma_share_mode shareMode; /* Set to whatever was passed in when the device was initialized. */
	var usingDefaultFormat: Bool;
	var usingDefaultChannels: Bool;
	var usingDefaultChannelMap: Bool;
	var format: Format;
	var channels: UInt32;
	var channelMap: cpp.RawPointer<Channel>;
	var internalFormat: Format;
	var internalChannels: UInt32;
	var internalSampleRate: UInt32;
	var internalChannelMap: cpp.RawPointer<Channel>;
	var internalBufferSizeInFrames: UInt32;
	var internalPeriods: UInt32;
	//     ma_pcm_converter converter;
	//     ma_uint32 _dspFrameCount; /* Internal use only. Used as the data source when reading from the device. */
	//     const ma_uint8* _dspFrames; /* ^^^ AS ABOVE ^^^ */
}

typedef CaptureInfo = PlaybackInfo;

@:structAccess
@:unreflective
extern class PlaybackConfig {
	// ma_device_id* pDeviceID;
	var format: Format;
	var channels: UInt32;
	var channelMap: cpp.RawPointer<Channel>;
	var shareMode: ShareMode;
}

typedef CaptureConfig = PlaybackConfig;

typedef DeviceDataCallback = Callable<(device: Star<Device>, output: Star<cpp.Void>, input: ConstStar<cpp.Void>, frameCount: UInt32) -> Void>;
typedef DeviceStopCallback = Callable<(device: Star<Device>) -> Void>;

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('ma_device_config') @:unreflective
@:structAccess
extern class DeviceConfig {

	var deviceType: DeviceType;
	var sampleRate: UInt32;
	var bufferSizeInFrames: UInt32;
	var bufferSizeInMilliseconds: UInt32;
	var periods: UInt32;
	var performanceProfile: PerformanceProfile;
	var noPreZeroedOutputBuffer: Bool;  /* When set to true, the contents of the output buffer passed into the data callback will be left undefined rather than initialized to zero. */
	var noClip: Bool;                   /* When set to true, the contents of the output buffer passed into the data callback will be clipped after returning. Only applies when the playback sample format is f32. */
	var dataCallback: DeviceDataCallback;
	var stopCallback: DeviceStopCallback;
	var pUserData: Star<cpp.Void>;
	var playback: PlaybackConfig;
	var capture: CaptureConfig;
	
	@:native('ma_device_config_init')
	static function init(type: DeviceType): DeviceConfig;
}

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('ma_device_info') @:unreflective
@:structAccess
extern class DeviceInfo {
	/* Basic info. This is the only information guaranteed to be filled in during device enumeration. */
	// var id: Any; // type is backend dependent

	/*
	Detailed info. As much of this is filled as possible with ma_context_get_device_info(). Note that you are allowed to initialize
	a device with settings outside of this range, but it just means the data will be converted using miniaudio's data conversion
	pipeline before sending the data to/from the device. Most programs will need to not worry about these values, but it's provided
	here mainly for informational purposes or in the rare case that someone might find it useful.

	These will be set to 0 when returned by ma_context_enumerate_devices() or ma_context_get_devices().
	*/
	var formatCount: UInt32;
	var formats: Star<Format>;
	var minChannels: UInt32;
	var maxChannels: UInt32;
	var minSampleRate: UInt32;
	var maxSampleRate: UInt32;
}

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('ma_device') @:unreflective
@:structAccess
extern class Device {

	var pContext: Star<Context>;
	var type: DeviceType;
	var sampleRate: UInt32;
	var state: UInt32;
	var onData: DeviceDataCallback;
	var onStop: DeviceStopCallback;
	var pUserData: Star<cpp.Void>;
	var lock: Mutex;
	var wakeupEvent: Event;
	var startEvent: Event;
	var stopEvent: Event;
	var thread: Thread;
	var workResult: Result; /* This is set by the worker thread after it's finished doing a job. */
	var usingDefaultSampleRate: Bool;
	var usingDefaultBufferSize: Bool;
	var usingDefaultPeriods: Bool;
	var isOwnerOfContext: Bool; /* When set to true, uninitializing the device will also uninitialize the context. Set to true when NULL is passed into ma_device_init(). */
	var noPreZeroedOutputBuffer: Bool;
	var noClip: Bool;
	var masterVolumeFactor: cpp.Float32;

	var playback: PlaybackInfo;
	var capture: CaptureInfo;

	inline function init(context: Star<Context>, config: Star<DeviceConfig>): Result {
		return untyped __global__.ma_device_init(context, config, (this: Star<Device>));
	}

	inline function uninit(): Void {
		untyped __global__.ma_device_uninit((this: Star<Device>));
	}

	inline function start(): Result {
		return untyped __global__.ma_device_start((this: Star<Device>));
	}

	inline function stop(): Result {
		return untyped __global__.ma_device_stop((this: Star<Device>));
	}

	@:native('~ma_device')
	function free(): Void;

	@:native('new ma_device')
	static function alloc(): Star<Device>; 

}

typedef DecoderReadCallback = Callable<(decoder: Star<Decoder>, outputBuffer: Star<cpp.Void>, bytesToRead: cpp.SizeT) -> cpp.SizeT>;
typedef DecoderSeekCallback = Callable<(decoder: Star<Decoder>, byteOffset: Int, origin: SeekOrigin) -> MaBool32>;
typedef DecoderGetLengthInPcmFramesCallback = Callable<(decoder: Star<Decoder>) -> UInt64>;

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('ma_decoder_config') @:unreflective
@:structAccess
extern class DecoderConfig {
	var format: Format;      /* Set to 0 or ma_format_unknown to use the stream's internal format. */
	var channels: UInt32;    /* Set to 0 to use the stream's internal channels. */
	var sampleRate: UInt32;  /* Set to 0 to use the stream's internal sample rate. */
	var channelMap: cpp.RawPointer<Channel>;
	// ma_channel_mix_mode channelMixMode;
	// ma_dither_mode ditherMode;
	// ma_src_algorithm srcAlgorithm;
	// union
	// {
	//     ma_src_config_sinc sinc;
	// } src;
	
	@:native('ma_decoder_config_init')
	static function init(outputFormat: Format, outputChannels: UInt32, outputSampleRate: UInt32): DecoderConfig;
}

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('ma_decoder') @:unreflective
@:structAccess
extern class Decoder {
	var onRead: DecoderReadCallback;
	var onSeek: DecoderSeekCallback;
	var pUserData: Star<cpp.Void>;
	var readPointer: UInt64; /* Used for returning back to a previous position after analysing the stream or whatnot. */
	var internalFormat: Format;
	var internalChannels: UInt32;
	var internalSampleRate: UInt32;
	var internalChannelMap: cpp.RawPointer<Channel>;
	var outputFormat: Format;
	var outputChannels: UInt32;
	var outputSampleRate: UInt32;
	var outputChannelMap: cpp.RawPointer<Channel>;
	// ma_pcm_converter dsp;   /* <-- Format conversion is achieved by running frames through this. */
	// ma_decoder_seek_to_pcm_frame_proc onSeekToPCMFrame;
	// ma_decoder_uninit_proc onUninit;
	var onGetLengthInPCMFrames: DecoderGetLengthInPcmFramesCallback;
	// void* pInternalDecoder; /* <-- The drwav/drflac/stb_vorbis/etc. objects. */
	// struct
	// {
	//     const ma_uint8* pData;
	//     size_t dataSize;
	//     size_t currentReadPos;
	// } memory;               /* Only used for decoders that were opened against a block of memory. */

	inline function init(onRead: DecoderReadCallback, onSeek: DecoderSeekCallback, userData: Star<cpp.Void>, config: ConstStar<DecoderConfig>): Result {
		return untyped __global__.ma_decoder_init(onRead, onSeek, userData, config, (this: Star<Decoder>));
	}

	inline function init_file(filePath: ConstCharStar, config: ConstStar<DecoderConfig>): Result {
		return untyped __global__.ma_decoder_init_file(filePath, config, (this: Star<Decoder>));
	}

	inline function init_memory(bytes: ConstStar<cpp.Void>, byteLength: cpp.SizeT, config: ConstStar<DecoderConfig>): Result {
		return untyped __global__.ma_decoder_init_memory(bytes, byteLength, config, (this: Star<Decoder>));
	}

	inline function init_memory_raw(bytes: ConstStar<cpp.Void>, byteLength: cpp.SizeT, configIn: ConstStar<DecoderConfig>, configOut: ConstStar<DecoderConfig>): Result {
		return untyped __global__.ma_decoder_init_memory_raw(bytes, byteLength, configIn, configOut, (this: Star<Decoder>));
	}

	inline function uninit(): Result {
		return untyped __global__.ma_decoder_uninit((this: Star<Decoder>));
	}

	/**
		Not thread-safe – audio thread may also be using the decoder, must synchronize before calling this
	**/
	inline function get_length_in_pcm_frames(): UInt64 {
		return untyped __global__.ma_decoder_get_length_in_pcm_frames((this: Star<Decoder>));
	}

	/**
		Not thread-safe – audio thread may also be using the decoder, must synchronize before calling this
	**/
	inline function read_pcm_frames(framesOut: Star<cpp.Void>, frameCount: UInt64): UInt64 {
		return untyped __global__.ma_decoder_read_pcm_frames((this: Star<Decoder>), framesOut, frameCount);
	}

	/**
		Not thread-safe – audio thread may also be using the decoder, must synchronize before calling this
	**/
	inline function seek_to_pcm_frame(frameIndex: UInt64): Result {
		return untyped __global__.ma_decoder_seek_to_pcm_frame((this: Star<Decoder>), frameIndex);
	}

	@:native('~ma_decoder')
	function free(): Void;

	@:native('new ma_decoder')
	static function alloc(): Star<Decoder>; 
}

/**
	Mutex should always be used as Star<Mutex> to avoid issues where the mutex is inadvertently copied
**/
@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('ma_mutex') @:unreflective
@:structAccess
extern class Mutex {
	var context: Star<Context>;

	/*
	A mutex must be created from a valid context. A mutex is initially unlocked.
	*/
	inline function init(context: Star<Context>): Result {
		return untyped __global__.ma_mutex_init(context, (this: Star<Mutex>));
	}

	inline function uninit(): Void {
		untyped __global__.ma_mutex_uninit((this: Star<Mutex>));
	}

	inline function lock(): Void {
		untyped __global__.ma_mutex_lock((this: Star<Mutex>));
	}

	inline function unlock(): Void {
		untyped __global__.ma_mutex_unlock((this: Star<Mutex>));
	}

	inline function locked<T>(callback: () -> T): T {
		// disable the GC while we're locked; this is so that if the native audio thread needs to acquire this lock it's not waiting on a GC pause (which could cause a audio stutter if long enough)
		// cpp.vm.Gc.enable(false); // this is commented out because I'm not convinced it's thread safe enough to call this (although it's just flipping a bool)
		this.lock();
		var returnVal = callback();
		this.unlock();
		// cpp.vm.Gc.enable(true);
		return returnVal;
	}

	@:native('~ma_mutex')
	function free(): Void;

	@:native('new ma_mutex')
	static function alloc(): Star<Mutex>; 

}

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('ma_thread') @:unreflective
@:structAccess
extern class Thread {
	var context: Star<Context>;
}

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('ma_event') @:unreflective
@:structAccess
extern class Event {
	var context: Star<Context>;
}

@:include('./native.h')
@:sourceFile(#if winrt './native.c' #else './native.m' #end)
@:native('ma_semaphore') @:unreflective
@:structAccess
extern class Semaphore {
	var context: Star<Context>;
}