#include <stdio.h>

// audio file decoders
#define DR_MP3_IMPLEMENTATION
#include "./miniaudio/extras/dr_mp3.h"

#define MINIAUDIO_IMPLEMENTATION

#include "./audio.h"

/**
 * AudioSource Implementation
 */
AudioSource* AudioSource_createFileSource(const char* path, ma_uint32 channelCount, ma_uint32 sampleRate, ma_result* pResult) {
    AudioSource* audioSource;

    audioSource = (AudioSource*)ma_malloc(sizeof(*audioSource));
    if (audioSource == NULL) {
        (*pResult) = MA_OUT_OF_MEMORY;
        return NULL;
    }
    ma_zero_object(audioSource);

    audioSource->maDecoder = (ma_decoder*)ma_malloc(sizeof(*audioSource->maDecoder));
    if (audioSource->maDecoder == NULL) {
        (*pResult) = MA_OUT_OF_MEMORY;
        return NULL;
    }
    ma_zero_object(audioSource->maDecoder);

    ma_decoder_config decoderConfig = ma_decoder_config_init(ma_format_f32, channelCount, sampleRate);

    (*pResult) = ma_decoder_init_file(path, &decoderConfig, audioSource->maDecoder);

    if ((*pResult) != MA_SUCCESS) {
        ma_decoder_uninit(audioSource->maDecoder);
        return NULL;
    }

    return audioSource;
}

void AudioSource_destroy(AudioSource* audioSource) {
    ma_decoder_uninit(audioSource->maDecoder);
    ma_free(audioSource->maDecoder);
    ma_free(audioSource);
}

/**
 * AudioOut Implementation
 */


// called from audio thread
void AudioOut_dataCallbackMixSources(ma_device* maDevice, void* pOutput, const void* pInput, ma_uint32 frameCount) {
    AudioOut* audioOut = (AudioOut*) maDevice->pUserData;

    static float decoderOutputBuffer[4096];

    ma_uint32 channelCount = maDevice->playback.channels;

    // @! can get seamless loops with a loop flag and seek
    ma_uint32 bufferMaxFrames = ma_countof(decoderOutputBuffer) / channelCount;

    ma_mutex_lock(&audioOut->sourceListLock);
    {
        AudioSourceListNode* currentSourceListNode = audioOut->sourceNext;
        while (currentSourceListNode != NULL) {

            ma_assert(currentSourceListNode->item != NULL);
            ma_assert(currentSourceListNode->item->maDecoder != NULL);

            ma_decoder* maDecoder = currentSourceListNode->item->maDecoder;

            // decoder should be setup to read into float buffers, if not then something has gone wrong
            if (maDecoder->outputFormat != ma_format_f32) {
                ma_post_error(maDevice, MA_LOG_LEVEL_ERROR, "decoder outputFormat was not ma_format_f32", MA_INVALID_OPERATION);
                continue;
            }

            // we expect the decoder to have the same number of channels as the output
            if (maDecoder->outputChannels != maDevice->playback.channels) {
                ma_post_error(maDevice, MA_LOG_LEVEL_ERROR, "decoder / device channel number mismatch", MA_INVALID_OPERATION);
                continue;
            }

            // read and mix frames in chunks of decoderOutputBuffer length
            ma_uint32 totalFramesRead = 0;
            ma_bool32 reachedEOF = MA_FALSE;
            while (totalFramesRead < frameCount) {
                ma_uint32 framesRemaining = frameCount - totalFramesRead;
                ma_uint32 framesToRead = ma_min(framesRemaining, bufferMaxFrames);

                ma_uint32 framesRead = (ma_uint32) ma_decoder_read_pcm_frames(maDecoder, decoderOutputBuffer, framesToRead);

                // mix decoderOutputBuffer with pOutput, applying conversions if the playback format is not float
                ma_uint32 sampleCount = framesRead * channelCount;
                ma_uint32 outputOffset = totalFramesRead * channelCount;

                float* mixBuffer = (float*)pOutput + outputOffset;

                for(ma_uint32 sampleIdx = 0; sampleIdx < sampleCount; ++sampleIdx) {
                    mixBuffer[sampleIdx] += decoderOutputBuffer[sampleIdx];
                }

                totalFramesRead += framesRead;

                if (framesRead < framesToRead) {
                    // we read less frames than we requested so we must have reached the end of this decoder
                    reachedEOF = MA_TRUE;
                    break;
                }
            }

            if (reachedEOF) {
                // trigger something
                // @! this doesn't account for the case were we read exactly  all of the frames
                // might need some thinking to enable seamless looping
            }

            currentSourceListNode = currentSourceListNode->next;
        }
    }
    ma_mutex_unlock(&audioOut->sourceListLock);
}

AudioOut* AudioOut_create(ma_uint32 sampleRate, ma_result* pResult) {
    AudioOut* audioOut = NULL;

    audioOut = (AudioOut*)ma_malloc(sizeof(*audioOut));
    if (audioOut == NULL) {
        *pResult = MA_OUT_OF_MEMORY;
        return NULL;
    }
    ma_zero_object(audioOut);

    audioOut->maDevice = (ma_device*)ma_malloc(sizeof(*audioOut->maDevice));
    if (audioOut->maDevice == NULL) {
        *pResult = MA_OUT_OF_MEMORY;
        return NULL;
    }
    ma_zero_object(audioOut->maDevice);

    // initialize a miniaudio device
    ma_device_config deviceConfig = ma_device_config_init(ma_device_type_playback);
    deviceConfig.sampleRate = sampleRate;
    deviceConfig.playback.format = ma_format_f32; // always use float32 sample input, miniaudio will convert if the device does not support this
    // deviceConfig.playback.channels = channelCount;
    deviceConfig.dataCallback = AudioOut_dataCallbackMixSources;
    deviceConfig.pUserData = NULL;

    (*pResult) = ma_device_init(NULL, &deviceConfig, audioOut->maDevice);
    if ((*pResult) != MA_SUCCESS) {
        ma_device_uninit(audioOut->maDevice);
        return NULL;
    }

    audioOut->maDevice->pUserData = audioOut;

    // initialize audioOut fields
    (*pResult) = ma_mutex_init(audioOut->maDevice->pContext, &audioOut->sourceListLock);
    if ((*pResult) != MA_SUCCESS) {
        ma_mutex_uninit(&audioOut->sourceListLock);
        return NULL;
    }
    
    return audioOut;
}

void AudioOut_destroy(AudioOut* audioOut) {
    ma_device_uninit(audioOut->maDevice);
    ma_mutex_uninit(&audioOut->sourceListLock);

    // free source list nodes
    AudioSourceListNode* currentSourceListNode = audioOut->sourceNext;
    while (currentSourceListNode != NULL) {
        ma_free(currentSourceListNode);
        currentSourceListNode = currentSourceListNode->next;
    }

    ma_free(audioOut->maDevice);
    ma_free(audioOut);
}

ma_result AudioOut_addSource(AudioOut* audioOut, AudioSource* source) {
    ma_result result = MA_SUCCESS;

    // create an empty list node
    AudioSourceListNode* newListNode;
    newListNode = (AudioSourceListNode*)ma_malloc(sizeof(*newListNode));
    if (newListNode == NULL) {
        return MA_OUT_OF_MEMORY;
    }
    ma_zero_object(newListNode);
    newListNode->item = source;

    ma_mutex_lock(&audioOut->sourceListLock);
    {
        // find last next-item pointer
        AudioSourceListNode** currentSourceListNodePtr = &(audioOut->sourceNext);
        while ((*currentSourceListNodePtr) != NULL) {
            currentSourceListNodePtr = &((*currentSourceListNodePtr)->next);
        }
        (*currentSourceListNodePtr) = newListNode;
    }
    ma_mutex_unlock(&audioOut->sourceListLock);

    return result;
}

ma_bool32 AudioOut_removeSource(AudioOut* audioOut, AudioSource* source) {
    ma_bool32 removed = MA_FALSE;

    ma_mutex_lock(&audioOut->sourceListLock);
    {
        // iterate list searching for source and remove when found
        AudioSourceListNode** parentSourceListNodePtr = &(audioOut->sourceNext);
        AudioSourceListNode* currentSourceListNode = audioOut->sourceNext;
        while (currentSourceListNode != NULL) {

            if (currentSourceListNode->item == source) {
                // found, link the parent pointer to the current's next, then free the current node since it's finished with
                *(parentSourceListNodePtr) = currentSourceListNode->next;
                ma_free(currentSourceListNode);
                removed = MA_TRUE;
                break;
            }

            parentSourceListNodePtr = &(currentSourceListNode->next);
            currentSourceListNode = currentSourceListNode->next;
        }
    }
    ma_mutex_unlock(&audioOut->sourceListLock);

    return removed;
}

int AudioOut_sourceCount(AudioOut* audioOut) {
    int count = 0;

    ma_mutex_lock(&audioOut->sourceListLock);
    {
        AudioSourceListNode* currentSourceListNode = audioOut->sourceNext;
        while (currentSourceListNode != NULL) {
            count++;
            currentSourceListNode = currentSourceListNode->next;
        }
    }
    ma_mutex_unlock(&audioOut->sourceListLock);

    return count;
}