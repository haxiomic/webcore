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
    // #define MA_DEBUG_OUTPUT
    #define MA_LOG_LEVEL 1
#endif

// disable some of the backends we don't need
#define MA_NO_JACK
#define MA_NO_SNDIO
#define MA_NO_AUDIO4
#define MA_NO_OSS
#define MA_NO_WEBAUDIO

#include "./miniaudio/miniaudio.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * AudioDecoder
 * 
 * Wraps a miniaudio decoder to enable thread-safety and tracks the current frameIndex
 */

typedef struct {
    ma_mutex*   lock;
    ma_decoder* maDecoder;
    ma_uint64   frameIndex;
} AudioDecoder;

/**
 * Thread-safe decoder functions
 */ 
ma_uint64 AudioDecoder_readPcmFrames(AudioDecoder* decoder, void* pFramesOut, ma_uint64 frameCount);
ma_uint64 AudioDecoder_getLengthInPcmFrames(AudioDecoder* decoder);
ma_result AudioDecoder_seekToPcmFrame(AudioDecoder* decoder, ma_uint64 frameIndex);

/**
 * AudioSource
 * 
 * lock should be used when reading or writing to any of the fields
 */

typedef struct {
    ma_mutex*           lock;
    AudioDecoder* decoder;
    // use atomics access for the following
    ma_bool32           playing;
    ma_bool32           loop;
    ma_bool32           onReachEofFlag;
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