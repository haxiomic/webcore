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

typedef struct {
    ma_decoder* maDecoder;

    // use atomics access for the following
    // ma_bool32 loop;
    // ma_bool32 isPlaying;
    // ma_bool32 onEndFlag;

} AudioSource;

typedef struct AudioSourceListNode {
    AudioSource* item;
    struct AudioSourceListNode* next;
} AudioSourceListNode;

typedef struct {
    ma_mutex lock; // acquire when accessing sourceNext list
    AudioSourceListNode* sourceNext;
} AudioSourceList;

void Audio_mixSources(ma_device* maDevice, void* pOutput, const void* pInput, ma_uint32 frameCount);

AudioSourceList* AudioSourceList_create(ma_context* context);
void AudioSourceList_destroy(AudioSourceList* instance);


void AudioSourceList_add(AudioSourceList* list, AudioSource* source);
ma_bool32 AudioSourceList_remove(AudioSourceList* list, AudioSource* source);
int AudioSourceList_sourceCount(AudioSourceList* list);

#ifdef __cplusplus
}
#endif

#endif