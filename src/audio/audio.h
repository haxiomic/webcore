/**
 * Minimalistic Audio Interface Abstraction
 * C89
 * @author George Corney (haxiomic)
 */

#ifndef AUDIO_H
#define AUDIO_H

#include "./miniaudio/miniaudio.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*ReadFrames)(int16_t* buffer, uint32_t frameCount);

/**
 * AudioSource Structure
 */
typedef struct {
    ReadFrames readFramesCallback;
} AudioSource;

typedef struct AudioSourceListNode {
    AudioSource* source;
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
AudioOut* AudioOut_create(ma_result* result);
void AudioOut_destroy(AudioOut* output);

ma_result AudioOut_addSource(AudioOut* output, AudioSource* source);
void AudioOut_removeSource(AudioOut* output, AudioSource* source);
int AudioOut_sourceCount(AudioOut* output);

#ifdef __cplusplus
}
#endif

#endif