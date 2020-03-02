// audio file decoders
#define DR_MP3_IMPLEMENTATION
#include "./miniaudio/extras/dr_mp3.h"
// other possible formats:
// #define DR_FLAC_IMPLEMENTATION
// #include "./miniaudio/extras/dr_flac.h"
// #define DR_WAV_IMPLEMENTATION
// #include "./miniaudio/extras/dr_wav.h"

// miniaudio implementation
#define MINIAUDIO_IMPLEMENTATION
#include "./native.h"

/**
 * AudioDecoder
 */

AudioDecoder* AudioDecoder_create(ma_context* context) {
    AudioDecoder* instance;

    instance = (AudioDecoder*)ma_malloc(sizeof(*instance));
    ma_zero_object(instance);

    // create lock
    instance->lock = (ma_mutex*)ma_malloc(sizeof(*instance->lock));

    // initialize audioNodeList fields
    ma_mutex_init(context, instance->lock);

    instance->maDecoder = (ma_decoder*)ma_malloc(sizeof(*instance->maDecoder));
    instance->frameIndex = 0;

    // maDecoder is uninitialized – should be initialized after calling create

    return instance;
}

void AudioDecoder_destroy(AudioDecoder* instance) {
    ma_mutex_uninit(instance->lock);
    ma_free(instance->lock);

    ma_decoder_uninit(instance->maDecoder);
    ma_free(instance->maDecoder);

    ma_free(instance);
}

ma_uint64 AudioDecoder_readPcmFrames(AudioDecoder* decoder, ma_uint64 frameCount, void* pFramesOut) {
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
 * AudioNode
 */

AudioNode* AudioNode_create(ma_context* context) {
    AudioNode* instance;

    instance = (AudioNode*)ma_malloc(sizeof(*instance));
    ma_zero_object(instance);

    // create lock
    instance->lock = (ma_mutex*)ma_malloc(sizeof(*instance->lock));
    ma_mutex_init(context, instance->lock);

    instance->readFramesCallback = NULL;
    instance->decoder = NULL;
    instance->active = MA_FALSE;
    instance->scheduledStartFrame = -1;
    instance->scheduledStopFrame = -1;
    instance->loop = MA_FALSE;
    instance->onReachEndFlag = MA_FALSE;
    instance->userData = NULL;
    instance->_lastReadFrameBlock = -1;

    return instance;
}

void AudioNode_destroy(AudioNode* instance) {
    ma_mutex_uninit(instance->lock);
    ma_free(instance->lock);
    ma_free(instance);
}

/**
 * AudioNodeList
 */

AudioNodeList* AudioNodeList_create(ma_context* context) {
    AudioNodeList* instance;

    instance = (AudioNodeList*)ma_malloc(sizeof(*instance));
    ma_zero_object(instance);

    // create lock
    instance->lock = (ma_mutex*)ma_malloc(sizeof(*instance->lock));
    ma_mutex_init(context, instance->lock);
    
    return instance;
}

void AudioNodeList_destroy(AudioNodeList* instance) {
    ma_mutex_uninit(instance->lock);
    ma_free(instance->lock);

    // free source list nodes
    AudioNodeListNode* currentSourceListNode = instance->sourceNext;
    while (currentSourceListNode != NULL) {
        ma_free(currentSourceListNode);
        currentSourceListNode = currentSourceListNode->next;
    }

    ma_free(instance);
}

void AudioNodeList_add(AudioNodeList* audioNodeList, AudioNode* source) {

    // create an empty list node
    AudioNodeListNode* newListNode;
    newListNode = (AudioNodeListNode*)ma_malloc(sizeof(*newListNode));
    ma_zero_object(newListNode);
    newListNode->item = source;

    ma_mutex_lock(audioNodeList->lock);
    {
        // find last next-item pointer
        AudioNodeListNode** currentSourceListNodePtr = &(audioNodeList->sourceNext);
        while ((*currentSourceListNodePtr) != NULL) {
            currentSourceListNodePtr = &((*currentSourceListNodePtr)->next);
        }
        (*currentSourceListNodePtr) = newListNode;
    }
    ma_mutex_unlock(audioNodeList->lock);
}

ma_bool32 AudioNodeList_remove(AudioNodeList* audioNodeList, AudioNode* source) {
    ma_bool32 removed = MA_FALSE;

    ma_mutex_lock(audioNodeList->lock);
    {
        // iterate list searching for source and remove when found
        AudioNodeListNode** parentSourceListNodePtr = &(audioNodeList->sourceNext);
        AudioNodeListNode* currentSourceListNode = audioNodeList->sourceNext;
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
    ma_mutex_unlock(audioNodeList->lock);

    return removed;
}

int AudioNodeList_sourceCount(AudioNodeList* audioNodeList) {
    int count = 0;

    ma_mutex_lock(audioNodeList->lock);
    {
        AudioNodeListNode* currentSourceListNode = audioNodeList->sourceNext;
        while (currentSourceListNode != NULL) {
            count++;
            currentSourceListNode = currentSourceListNode->next;
        }
    }
    ma_mutex_unlock(audioNodeList->lock);

    return count;
}

/**
 * Global Audio Methods
 */

/**
 * Sample-rate and channels must be the same for the all decoders in sourceList and output
 */
ma_uint32 Audio_mixSources(AudioNodeList* sourceList, ma_uint32 channelCount, ma_uint32 frameCount, ma_int64 schedulingCurrentFrameBlock, float* pOutput) {
    if (sourceList == NULL) {
        return 0;
    }

    static float decoderOutputBuffer[4096];
    // clear the scratch buffer to 0, this is required because we might not replace all the bytes when reading
    // (as scheduling makes it possible to create gaps)
    memset(decoderOutputBuffer, 0, frameCount * channelCount);

    ma_uint32 bufferMaxFrames = ma_countof(decoderOutputBuffer) / channelCount;
    ma_uint32 writtenDataWidth = 0;

    ma_mutex_lock(sourceList->lock);
    {
        AudioNodeListNode* currentSourceListNode = sourceList->sourceNext;
        while (currentSourceListNode != NULL) {
            AudioNode* source = currentSourceListNode->item;
            currentSourceListNode = currentSourceListNode->next;

            ma_assert(source != NULL);

            // we lock with the source object for the entire duration of the mix because if the source fields it's possible that references like the decoder are freed by the GC
            ma_mutex_lock(source->lock); {

                ma_int64 _lastReadFrameBlock;
                _lastReadFrameBlock = source->_lastReadFrameBlock;
                // mark for this frame block
                source->_lastReadFrameBlock = schedulingCurrentFrameBlock;

                if (source->active != MA_TRUE) {
                    goto NEXT_SOURCE;
                }

                // if we've already read from this node for this frame block, then don't read again (this prevent cycles in the node tree)
                if (_lastReadFrameBlock == schedulingCurrentFrameBlock) {
                    goto NEXT_SOURCE;
                }

                ma_int64 localStartFrame = 0;
                ma_int64 localEndFrame = frameCount; // exclusive

                // if we have a scheduled start frame, then compute the frame count subset and block offset
                if (source->scheduledStartFrame != -1) {
                    localStartFrame = ma_max(source->scheduledStartFrame - schedulingCurrentFrameBlock, 0);

                    // return if start is scheduled outside this block
                    if (localStartFrame >= frameCount) {
                        goto NEXT_SOURCE;
                    }
                }

                // clamp localEndFrame to scheduledStopFrame if we have a scheduled stop
                if (source->scheduledStopFrame != -1) {
                    localEndFrame = ma_min(source->scheduledStopFrame - schedulingCurrentFrameBlock, frameCount);

                    // if stop is scheduled within this block, then this triggers end flag
                    if (localEndFrame < frameCount) {
                        source->onReachEndFlag = MA_TRUE;
                    }
                }

                // determine total frames to read from scheduling adjusted start and end frame
                ma_int64 totalFramesToRead = localEndFrame - localStartFrame;

                // scheduled out of this block, don't read
                if (totalFramesToRead <= 0) {
                    goto NEXT_SOURCE; 
                }

                // if we have neither a read frames callback or a decoder then we can't read anything
                if (source->readFramesCallback == NULL && source->decoder == NULL) goto NEXT_SOURCE;

                // if we do have a decoder, validate that it has the right output format and channel count
                if (source->decoder != NULL) {
                    // decoder should be setup to read into float buffers, if not then something has gone wrong
                    if (source->decoder->maDecoder->outputFormat != ma_format_f32) {
                        // error, output format must be F32
                        goto NEXT_SOURCE;
                    }

                    // we expect the decoder to have the same number of channels as the output
                    if (source->decoder->maDecoder->outputChannels != channelCount) {
                        // error, channel count mismatch
                        goto NEXT_SOURCE;
                    }
                }

                // read and mix frames in chunks of decoderOutputBuffer length
                ma_uint32 totalFramesRead = 0;
                int loopIndex = -1;
                ma_bool32 reachedBytesEndFlag = MA_FALSE;
                while (totalFramesRead < totalFramesToRead) {
                    loopIndex++;
                    ma_uint32 framesRemaining = totalFramesToRead - totalFramesRead;
                    ma_uint32 chunkFrameCount = ma_min(framesRemaining, bufferMaxFrames);
                    
                    ma_uint32 framesRead;
                    if (source->readFramesCallback != NULL) {
                        // be aware: the callback should not lock with the source (because it's already locked)
                        framesRead = source->readFramesCallback(source->userData, channelCount, chunkFrameCount, schedulingCurrentFrameBlock, decoderOutputBuffer);
                    } else if (source->decoder != NULL) {
                        framesRead = (ma_uint32) AudioDecoder_readPcmFrames(source->decoder, chunkFrameCount, decoderOutputBuffer);
                    } else {
                        break;
                    }

                    // mix decoderOutputBuffer with pOutput, applying conversions if the playback format is not float
                    ma_uint32 sampleCount = framesRead * channelCount;
                    ma_uint32 chunkOffset = totalFramesRead * channelCount;
                    ma_uint32 startOffset = localStartFrame * channelCount;

                    #ifdef HXCPP_DEBUG
                    // validate we don't overflow
                    ma_uint32 sampleEnd = (chunkOffset + startOffset + sampleCount);
                    ma_uint32 sampleLimit = (frameCount * channelCount);
                    if (sampleEnd > sampleLimit) {
                        printf("Error: Overflowing mixBuffer, %d > %d\n", sampleEnd, sampleLimit);
                    }
                    #endif

                    float* mixBuffer = pOutput + chunkOffset + startOffset;

                    // with compiler optimizations enabled, this should vectorize
                    for(ma_uint32 sampleIdx = 0; sampleIdx < sampleCount; ++sampleIdx) {
                        mixBuffer[sampleIdx] += decoderOutputBuffer[sampleIdx];
                    }

                    totalFramesRead += framesRead;

                    if (framesRead < chunkFrameCount) {
                        // we read less frames than we requested so we must have reached the end of this decoder
                        reachedBytesEndFlag = MA_TRUE;

                        // if the decoder returns 0 frames after the first iteration (we've given it a chance to loop), then the decoder is probably empty; break to avoid infinite loop
                        if (framesRead == 0 && loopIndex >= 1) {
                            break;
                        }

                        // if looping, seek to start and continue to read more frames
                        if (source->loop == MA_TRUE && source->decoder != NULL) {
                            AudioDecoder_seekToPcmFrame(source->decoder, 0);
                            continue;
                        } else {
                            break;
                        }
                    }
                }

                // update high water mark for width of data written
                writtenDataWidth = ma_max(writtenDataWidth, localStartFrame + totalFramesRead);

                if (reachedBytesEndFlag) {
                    source->onReachEndFlag = MA_TRUE;
                }

            }
            NEXT_SOURCE: // unlock from current source before next loop 
            ma_mutex_unlock(source->lock);
        }
    }
    ma_mutex_unlock(sourceList->lock);

    return writtenDataWidth;
}