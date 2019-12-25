/**
 * Minimalistic Audio Interface Abstraction
 * C89
 * 
 * Defines
 *  - AudioOut
 *  - AudioSource
 * @author George Corney (haxiomic)
 */

#ifndef AUDIO_H
#define AUDIO_H

#ifdef HXCPP_DEBUG
    #define MA_DEBUG_OUTPUT
    #define MA_LOG_LEVEL 1
#endif
#include "./miniaudio/miniaudio.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * AudioSource Structure
 */
typedef struct {
    ma_decoder* maDecoder;
} AudioSource;

/**
 * AudioSource Methods
 */
AudioSource* AudioSource_createFileSource(const char* path, ma_uint32 channelCount, ma_uint32 sampleRate, ma_result* pResult);
void AudioSource_destroy(AudioSource* audioSource);

typedef struct AudioSourceListNode {
    AudioSource* item;
    struct AudioSourceListNode* next;
} AudioSourceListNode;

/**
 * AudioOut Structure
 */
typedef struct {
    ma_device* maDevice;
    ma_mutex sourceListLock; // acquire when accessing sourceNext list
    AudioSourceListNode* sourceNext;
} AudioOut;

/**
 * AudioOut Methods
 */
AudioOut* AudioOut_create(ma_uint32 sampleRate, ma_result* pResult);
void AudioOut_destroy(AudioOut* output);

ma_result AudioOut_addSource(AudioOut* output, AudioSource* source);
ma_bool32 AudioOut_removeSource(AudioOut* output, AudioSource* source);
int AudioOut_sourceCount(AudioOut* output);

#ifdef __cplusplus
}
#endif

#endif