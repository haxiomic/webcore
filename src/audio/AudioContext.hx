package audio;

#if js

typedef AudioContextOptions = js.html.audio.AudioContextOptions;
typedef AudioContext = js.html.audio.AudioContext;

#else

typedef AudioContextOptions = {
	var ?sampleRate : Float;
    /**
        Audio device ID
    **/
    var ?sinkId: String;
}

class AudioContext extends BaseAudioContext {

    /**
        @throws * if could not create context
    **/
    public function new(?contextOptions : AudioContextOptions) {
        // default sample rate = 44100
        /*
        deviceConfig = ma_device_config_init(ma_device_type_playback);
        deviceConfig.playback.format   = sampleFormat;
        deviceConfig.playback.channels = channelCount;
        deviceConfig.sampleRate        = sampleRate;
        deviceConfig.dataCallback      = data_callback;
        deviceConfig.pUserData         = NULL;

        ma_result initResult = ma_device_init(NULL, &deviceConfig, &device);
        if (ma_device_init(NULL, &deviceConfig, &device) != MA_SUCCESS) {
            for (iDecoder = 0; iDecoder < g_decoderCount; ++iDecoder) {
                ma_decoder_uninit(&g_pDecoders[iDecoder]);
            }
            free(g_pDecoders);
            free(g_pDecodersAtEnd);

            printf("Failed to open playback device.\n");
            return -3;
        }
        */
    }

}

class BaseAudioContext {

    public var destination(default, null): AudioDestinationNode;

    public function decodeAudioData(audioData: typedarray.ArrayBuffer, ?successCallback: AudioBuffer -> Void, ?errorCallback: Any -> Void ): Void {
        trace('todo');
    }

    public function createBufferSource() : AudioBufferSourceNode {
        trace('todo');
        return null;
    }

}

#end