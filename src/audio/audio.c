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

    float decoderOutputBuffer[4096];

    // @! currently: this assumes just a single source, no mixing
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
            ma_uint32 bufferMaxFrames = ma_countof(decoderOutputBuffer) / maDecoder->outputChannels;
            ma_uint32 totalFramesRead = 0;
            while (totalFramesRead < frameCount) {
                ma_uint32 framesRemaining = frameCount - totalFramesRead;
                ma_uint32 framesToRead = ma_min(framesRemaining, bufferMaxFrames);

                ma_uint32 framesRead = (ma_uint32) ma_decoder_read_pcm_frames(maDecoder, decoderOutputBuffer, framesToRead);

                // no more frames left to read in this decoder
                if (framesRead == 0) {
                    break;
                }

                // mix decoderOutputBuffer with pOutput
                ma_uint32 sampleCount = framesRead * maDecoder->outputChannels;
                ma_uint32 outputOffset = totalFramesRead * maDecoder->outputChannels;
                for(ma_uint32 sampleIdx = 0; sampleIdx < sampleCount; ++sampleIdx) {
                    float sample = decoderOutputBuffer[sampleIdx];
                    
                    // if the playback output buffer is float32 then we can just add, otherwise we need to convert
                    switch (maDevice->playback.format) {
                        case ma_format_f32: {
                            // by default minaudio will handle float clipping
                            ((float*)pOutput)[outputOffset + sampleIdx] += sample;
                        } break;
                        case ma_format_s16: {
                            float currentSample = (float)((ma_int16*)pOutput)[outputOffset + sampleIdx];
                            float summedAndClippedSample = ma_clamp(sample + currentSample, -1.0, 1.0);
                            ((ma_int16*)pOutput)[outputOffset + sampleIdx] += (ma_int16)(summedAndClippedSample * 32767);
                        } break;
                        case ma_format_s32: {
                            float currentSample = (float)((ma_int32*)pOutput)[outputOffset + sampleIdx];
                            float summedAndClippedSample = ma_clamp(sample + currentSample, -1.0, 1.0);
                            ((ma_int32*)pOutput)[outputOffset + sampleIdx] += (ma_int32)(summedAndClippedSample * 2147483647);
                        } break;
                        // unsupported
                        case ma_format_u8: { } break;
                        case ma_format_s24: { } break;
                    }
                }

                totalFramesRead += framesRead;

                if (framesRead < framesToRead) {
                    // we read less frames than we requested so we must have reached the end of this decoder
                    break;
                }
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
    // deviceConfig.playback.format = format;
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