/**
 * This file include miniaudio.h with #define flags and provides helper utilities, including
 * - Thread-safe linked list to track audio source references between the audio thread and haxe thread
 * - Audio source abstraction with looping and play-state
 * - An audio mixer function to use as the dataCallback in miniaudio.h
 * 
 * @author George Corney (haxiomic)
 */

#ifndef AUDIO_NATIVE_NATIVE_H
#define AUDIO_NATIVE_NATIVE_H

#ifdef HXCPP_DEBUG
    #define MA_DEBUG_OUTPUT
    #define MA_LOG_LEVEL 1
#endif
#include "./miniaudio/miniaudio.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * NativeAudioDecoder
 */

typedef struct {
    ma_decoder* maDecoder;
    ma_mutex*   lock;
    ma_uint64   frameIndex;
} NativeAudioDecoder;

ma_uint64 NativeAudioDecoder_readPcmFrames(NativeAudioDecoder* decoder, void* pFramesOut, ma_uint64 frameCount);
ma_uint64 NativeAudioDecoder_getLengthInPcmFrames(NativeAudioDecoder* decoder);
ma_result NativeAudioDecoder_seekToPcmFrame(NativeAudioDecoder* decoder, ma_uint64 frameIndex);

/**
 * AudioSource
 */

typedef struct {
    NativeAudioDecoder* decoder;
    // use atomics access for the following
    // ma_bool32 loop;
    // ma_bool32 isPlaying;
    // ma_bool32 onReadEofFlag;
} AudioSource;


/**
 * AudioSourceListNode
 * 
 */

typedef struct AudioSourceListNode {
    AudioSource*                item;
    struct AudioSourceListNode* next;
} AudioSourceListNode;


/**
 * AudioSourceList
 * Linked-list of AudioSources with a miniaudio mutex lock
 */

typedef struct {
    ma_mutex             lock; // acquire when accessing sourceNext list
    AudioSourceListNode* sourceNext;
} AudioSourceList;


AudioSourceList* AudioSourceList_create(ma_context* context);
void             AudioSourceList_destroy(AudioSourceList* instance);

void      AudioSourceList_add(AudioSourceList* list, AudioSource* source);
ma_bool32 AudioSourceList_remove(AudioSourceList* list, AudioSource* source);
int       AudioSourceList_sourceCount(AudioSourceList* list);


/**
 * Global Audio Functions
 */

void Audio_mixSources(ma_device* maDevice, void* pOutput, const void* pInput, ma_uint32 frameCount);

#ifdef __cplusplus
}
#endif

#endif