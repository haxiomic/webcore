// audio file decoders
#define DR_MP3_IMPLEMENTATION
#include "./miniaudio/extras/dr_mp3.h"
// other possible formats:
// #include "./miniaudio/extras/dr_flac.h"
// #include "./miniaudio/extras/dr_wav.h"

// miniaudio implementation
#define MINIAUDIO_IMPLEMENTATION
#include "./native.h"

/**
 * AudioDecoder
 */

ma_uint64 AudioDecoder_readPcmFrames(AudioDecoder* decoder, void* pFramesOut, ma_uint64 frameCount) {
    ma_uint64 framesRead = 0;
    ma_mutex_lock(decoder->lock);
    framesRead = ma_decoder_read_pcm_frames(decoder->maDecoder, pFramesOut, frameCount);
    decoder->frameIndex += framesRead;
    ma_mutex_unlock(decoder->lock);
    return framesRead;
}

ma_uint64 AudioDecoder_getLengthInPcmFrames(AudioDecoder* decoder) {
    ma_uint64 length = 0;
    ma_mutex_lock(decoder->lock);
    length = ma_decoder_get_length_in_pcm_frames(decoder->maDecoder);
    ma_mutex_unlock(decoder->lock);
    return length;
}

ma_result AudioDecoder_seekToPcmFrame(AudioDecoder* decoder, ma_uint64 frameIndex) {
    ma_result result = MA_ERROR;
    ma_mutex_lock(decoder->lock);
    result = ma_decoder_seek_to_pcm_frame(decoder->maDecoder, frameIndex);
    decoder->frameIndex = frameIndex;
    ma_mutex_unlock(decoder->lock);
    return result;
}

/**
 * AudioSourceList
 */

AudioSourceList* AudioSourceList_create(ma_context* context) {
    AudioSourceList* instance = NULL;

    instance = (AudioSourceList*)ma_malloc(sizeof(*instance));
    ma_zero_object(instance);

    // initialize audioSourceList fields
    ma_result r = ma_mutex_init(context, &instance->lock);
    if (r != MA_SUCCESS) {
        ma_mutex_uninit(&instance->lock);
        return NULL;
    }
    
    return instance;
}

void AudioSourceList_destroy(AudioSourceList* instance) {
    ma_mutex_uninit(&instance->lock);

    // free source list nodes
    AudioSourceListNode* currentSourceListNode = instance->sourceNext;
    while (currentSourceListNode != NULL) {
        ma_free(currentSourceListNode);
        currentSourceListNode = currentSourceListNode->next;
    }

    ma_free(instance);
}

void AudioSourceList_add(AudioSourceList* audioSourceList, AudioSource* source) {

    // create an empty list node
    AudioSourceListNode* newListNode;
    newListNode = (AudioSourceListNode*)ma_malloc(sizeof(*newListNode));
    ma_zero_object(newListNode);
    newListNode->item = source;

    ma_mutex_lock(&audioSourceList->lock);
    {
        // find last next-item pointer
        AudioSourceListNode** currentSourceListNodePtr = &(audioSourceList->sourceNext);
        while ((*currentSourceListNodePtr) != NULL) {
            currentSourceListNodePtr = &((*currentSourceListNodePtr)->next);
        }
        (*currentSourceListNodePtr) = newListNode;
    }
    ma_mutex_unlock(&audioSourceList->lock);
}

ma_bool32 AudioSourceList_remove(AudioSourceList* audioSourceList, AudioSource* source) {
    ma_bool32 removed = MA_FALSE;

    ma_mutex_lock(&audioSourceList->lock);
    {
        // iterate list searching for source and remove when found
        AudioSourceListNode** parentSourceListNodePtr = &(audioSourceList->sourceNext);
        AudioSourceListNode* currentSourceListNode = audioSourceList->sourceNext;
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
    ma_mutex_unlock(&audioSourceList->lock);

    return removed;
}

int AudioSourceList_sourceCount(AudioSourceList* audioSourceList) {
    int count = 0;

    ma_mutex_lock(&audioSourceList->lock);
    {
        AudioSourceListNode* currentSourceListNode = audioSourceList->sourceNext;
        while (currentSourceListNode != NULL) {
            count++;
            currentSourceListNode = currentSourceListNode->next;
        }
    }
    ma_mutex_unlock(&audioSourceList->lock);

    return count;
}

/**
 * Global Audio Methods
 */

void Audio_mixSources(ma_device* maDevice, void* pOutput, const void* pInput, ma_uint32 frameCount) {
    AudioSourceList* sourceList = (AudioSourceList*) maDevice->pUserData;

    if (sourceList == NULL) {
        return;
    }

    static float decoderOutputBuffer[4096];

    ma_uint32 channelCount = maDevice->playback.channels;
    ma_uint32 bufferMaxFrames = ma_countof(decoderOutputBuffer) / channelCount;

    ma_mutex_lock(&sourceList->lock);
    {
        AudioSourceListNode* currentSourceListNode = sourceList->sourceNext;
        while (currentSourceListNode != NULL) {
            AudioSource* source = currentSourceListNode->item;
            currentSourceListNode = currentSourceListNode->next;

            ma_assert(source != NULL);

            ma_bool32 playing = MA_FALSE;
            AudioDecoder* decoder = NULL;
            ma_bool32 loop = MA_FALSE;
            ma_mutex_lock(source->lock); {
                playing = source->playing;
                decoder = source->decoder;
                loop = source->loop;
            }
            ma_mutex_unlock(source->lock);

            if (playing != MA_TRUE) {
                continue;
            }

            // maDecoder is allowed to be NULL
            if (decoder == NULL) continue;

            // decoder should be setup to read into float buffers, if not then something has gone wrong
            if (decoder->maDecoder->outputFormat != ma_format_f32) {
                ma_post_error(maDevice, MA_LOG_LEVEL_ERROR, "decoder outputFormat was not ma_format_f32", MA_INVALID_OPERATION);
                continue;
            }

            // we expect the decoder to have the same number of channels as the output
            if (decoder->maDecoder->outputChannels != maDevice->playback.channels) {
                ma_post_error(maDevice, MA_LOG_LEVEL_ERROR, "decoder / device channel number mismatch", MA_INVALID_OPERATION);
                continue;
            }

            // read and mix frames in chunks of decoderOutputBuffer length
            ma_uint32 totalFramesRead = 0;
            ma_bool32 reachedEOF = MA_FALSE;
            int loopIndex = -1;
            while (totalFramesRead < frameCount) {
                loopIndex++;
                ma_uint32 framesRemaining = frameCount - totalFramesRead;
                ma_uint32 framesToRead = ma_min(framesRemaining, bufferMaxFrames);

                ma_uint32 framesRead = (ma_uint32) AudioDecoder_readPcmFrames(decoder, decoderOutputBuffer, framesToRead);

                // mix decoderOutputBuffer with pOutput, applying conversions if the playback format is not float
                ma_uint32 sampleCount = framesRead * channelCount;
                ma_uint32 outputOffset = totalFramesRead * channelCount;

                float* mixBuffer = (float*)pOutput + outputOffset;

                // with compiler optimizations enabled, this should vectorize
                for(ma_uint32 sampleIdx = 0; sampleIdx < sampleCount; ++sampleIdx) {
                    mixBuffer[sampleIdx] += decoderOutputBuffer[sampleIdx];
                }

                totalFramesRead += framesRead;

                if (framesRead < framesToRead) {
                    // we read less frames than we requested so we must have reached the end of this decoder
                    reachedEOF = MA_TRUE;

                    // if the decoder returns 0 frames after the first iteration (we've given it a chance to loop), then the decoder is probably empty; break to avoid infinite loop
                    if (framesRead == 0 && loopIndex >= 1) {
                        break;
                    }

                    // if looping, seek to start and continue to read more frames
                    if (loop == MA_TRUE) {
                        AudioDecoder_seekToPcmFrame(decoder, 0);
                        continue;
                    } else {
                        break;
                    }
                }
            }

            if (reachedEOF) {
                ma_mutex_lock(source->lock); {
                    source->onReachEofFlag = MA_TRUE;
                }
                ma_mutex_unlock(source->lock);
            }
        }
    }
    ma_mutex_unlock(&sourceList->lock);
}