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
 * AudioDevice Structure
 */
typedef struct {
    ma_device* maDevice;
    ma_mutex sourceListLock; // acquire when accessing sourceNext list
    AudioSourceListNode* sourceNext;
} AudioDevice;

/**
 * AudioDevice Methods
 */
AudioDevice* AudioDevice_create(ma_result* result);
void AudioDevice_destroy(AudioDevice* device);

ma_result AudioDevice_addSource(AudioDevice* device, AudioSource* source);
void AudioDevice_removeSource(AudioDevice* device, AudioSource* source);
int AudioDevice_sourceCount(AudioDevice* device);

#ifdef __cplusplus
}
#endif

#endif