package audio.native;

import cpp.*;

@:include('./audio.h')
@:sourceFile('./audio.c')
extern class MiniAudio { }

/*
    MINIAUDIO Enums
*/
extern enum abstract Backend(MaBackend) {
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
@:include('./audio.h')
@:sourceFile('./audio.c')
@:unreflective @:native('ma_backend')
private extern class MaBackend {}

extern enum abstract ThreadPriority(MaThreadPriority) {
    @:native('ma_thread_priority_idle') var IDLE;
    @:native('ma_thread_priority_lowest') var LOWEST;
    @:native('ma_thread_priority_low') var LOW;
    @:native('ma_thread_priority_normal') var NORMAL;
    @:native('ma_thread_priority_high') var HIGH;
    @:native('ma_thread_priority_highest') var HIGHEST;
    @:native('ma_thread_priority_realtime') var REALTIME;
    @:native('ma_thread_priority_default') var DEFAULT;
}
@:include('./audio.h')
@:sourceFile('./audio.c')
@:native('ma_thread_priority') @:unreflective 
private extern class MaThreadPriority {}

extern enum abstract Format(MaFormat) {
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
}
@:include('./audio.h')
@:sourceFile('./audio.c')
@:native('ma_format') @:unreflective
private extern class MaFormat {}

extern enum abstract DeviceType(MaDeviceType) {
    @:native('ma_device_type_playback') var PLAYBACK;
    @:native('ma_device_type_capture') var CAPTURE;
    @:native('ma_device_type_duplex') var DUPLEX;
    @:native('ma_device_type_loopback') var LOOPBACK;
}
@:include('./audio.h')
@:sourceFile('./audio.c')
@:native('ma_device_type') @:unreflective
private extern class MaDeviceType {}

@:include('./audio.h')
@:sourceFile('./audio.c')
extern enum abstract Result(MaResult) {
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

    @:to inline function toInt(): Int {
        return cast this;
    }

    inline function toString(): String {
        return ResultLookup.getString(cast this);
    }
}
@:include('./audio.h')
@:sourceFile('./audio.c')
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

/*
    MINIAUDIO Configuration Structures
*/
@:include('./audio.h')
@:sourceFile('./audio.c')
@:native('ma_context_config') @:unreflective
@:structAccess
extern class ContextConfig {
    var threadPriority: ThreadPriority;
    var pUserData: Star<cpp.Void>;
    // ma_log_proc logCallback;
    static inline function init(): ContextConfig {
        return untyped __global__.ma_context_config_init();
    } 
}

@:include('./audio.h')
@:sourceFile('./audio.c')
@:native('ma_context') @:unreflective
@:structAccess
extern class Context {

    var backend: Backend;
    // ma_log_proc logCallback;
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

    @:native('~ma_context')
    function free(): Void;

    @:native('new ma_context')
    static function alloc(): Star<Context>;

    static inline function init(?backends: Array<Backend>, config: Star<ContextConfig>, context: Star<Context>): Star<Context> {
        var backendCount = backends != null ? backends.length : 0;
        var backendsPointer = backends == null ? null : NativeArray.address(backends, 0);
        return untyped __global__.ma_context_init(backendsPointer, backendCount, config, context);
    }

    @:native('ma_context_uninit')
    static function uninit(context: Star<Context>): Result;

}

@:structAccess
extern class PlaybackInfo {
    //     char name[256]; /* Maybe temporary. Likely to be replaced with a query API. */
    //     ma_share_mode shareMode; /* Set to whatever was passed in when the device was initialized. */
    var usingDefaultFormat: Bool;
    var usingDefaultChannels: Bool;
    var usingDefaultChannelMap: Bool;
    var format: Format;
    var channels: UInt32;
    //     ma_channel channelMap[MA_MAX_CHANNELS];
    var internalFormat: Format;
    var internalChannels: UInt32;
    var internalSampleRate: UInt32;
    //     ma_channel internalChannelMap[MA_MAX_CHANNELS];
    var internalBufferSizeInFrames: UInt32;
    var internalPeriods: UInt32;
    //     ma_pcm_converter converter;
    //     ma_uint32 _dspFrameCount; /* Internal use only. Used as the data source when reading from the device. */
    //     const ma_uint8* _dspFrames; /* ^^^ AS ABOVE ^^^ */
}

typedef CaptureInfo = PlaybackInfo;

@:include('./audio.h')
@:sourceFile('./audio.c')
@:native('ma_device') @:unreflective
@:structAccess
extern class Device {

    var pContext: Star<Context>;
    var type: DeviceType;
    var sampleRate: UInt32;
    var state: UInt32;
    // ma_device_callback_proc onData;
    // ma_stop_proc onStop;
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

    inline function start(): Result {
        return untyped __global__.ma_device_start(this);
    }

    inline function stop(): Result {
        return untyped __global__.ma_device_stop(this);
    }

}

@:include('./audio.h')
@:sourceFile('./audio.c')
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

@:include('./audio.h')
@:sourceFile('./audio.c')
@:native('ma_mutex') @:unreflective
extern class Mutex {
    var context: Star<Context>;
}

@:include('./audio.h')
@:sourceFile('./audio.c')
@:native('ma_thread') @:unreflective
extern class Thread {
    var context: Star<Context>;
}

@:include('./audio.h')
@:sourceFile('./audio.c')
@:native('ma_event') @:unreflective
extern class Event {
    var context: Star<Context>;
}

@:include('./audio.h')
@:sourceFile('./audio.c')
@:native('ma_semaphore') @:unreflective
extern class Semaphore {
    var context: Star<Context>;
}