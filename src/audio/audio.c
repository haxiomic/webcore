#include <stdio.h>
#include "./audio.h"

#ifdef HXCPP_DEBUG
    #define MA_DEBUG_OUTPUT
#endif
#define MINIAUDIO_IMPLEMENTATION
#include "./miniaudio/miniaudio.h"

/**
 * AudioOut Implementation
 */

// called from audio thread
void AudioOut_dataCallback(ma_device* maDevice, void* pOutput, const void* pInput, ma_uint32 frameCount) {
    printf("data_callback %u \n", frameCount);

    AudioOut* audioOut = (AudioOut*) maDevice->pUserData;

    // @! we should copy out the callback pointers to minimize time with mutex held
    ma_mutex_lock(&audioOut->sourceListLock);
    {
        AudioSourceListNode* currentSourceListNode = audioOut->sourceNext;
        while (currentSourceListNode != NULL) {
            // currentSourceListNode->source->readFramesCallback()
            currentSourceListNode = currentSourceListNode->next;
        }
    }
    ma_mutex_unlock(&audioOut->sourceListLock);
}

AudioOut* AudioOut_create(ma_result* pResult) {
    AudioOut* audioOut = NULL;
    ma_device* maDevice = NULL;

    maDevice = (ma_device*)ma_malloc(sizeof(*maDevice));
    if (maDevice == NULL) {
        *pResult = MA_OUT_OF_MEMORY;
        return NULL;
    }
    ma_zero_object(maDevice);

    audioOut = (AudioOut*)ma_malloc(sizeof(*audioOut));
    if (audioOut == NULL) {
        *pResult = MA_OUT_OF_MEMORY;
        return NULL;
    }
    ma_zero_object(audioOut);

    // initialize a miniaudio audioOut
    ma_device_config deviceConfig;
    deviceConfig = ma_device_config_init(ma_device_type_playback);
    // deviceConfig.playback.format = sampleFormat;
    // deviceConfig.playback.channels = channelCount;
    // deviceConfig.sampleRate = sampleRate;
    deviceConfig.dataCallback = AudioOut_dataCallback;
    deviceConfig.pUserData = NULL;

    (*pResult) = ma_device_init(NULL, &deviceConfig, maDevice);
    if ((*pResult) != MA_SUCCESS) {
        return NULL;
    }

    // setup audioOut fields
    audioOut->maDevice = maDevice;
    maDevice->pUserData = audioOut;
    (*pResult) = ma_mutex_init(maDevice->pContext, &audioOut->sourceListLock);
    if ((*pResult) != MA_SUCCESS) {
        return NULL;
    }
    
    return audioOut;
}

void AudioOut_destroy(AudioOut* audioOut) {
    if (audioOut != NULL) {
        ma_device_uninit(audioOut->maDevice);
        ma_mutex_uninit(&audioOut->sourceListLock);

        ma_free(audioOut->maDevice);
        ma_free(audioOut);
    }
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
    newListNode->source = source;

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

void AudioOut_removeSource(AudioOut* audioOut, AudioSource* source) {
    ma_mutex_lock(&audioOut->sourceListLock);
    {
        // iterate list searching for source and remove when found
        AudioSourceListNode** parentSourceListNodePtr = &(audioOut->sourceNext);
        AudioSourceListNode* currentSourceListNode = audioOut->sourceNext;
        while (currentSourceListNode != NULL) {

            if (currentSourceListNode->source == source) {
                // found, link the parent pointer to the current's next, then free the current node since it's finished with
                *(parentSourceListNodePtr) = currentSourceListNode->next;
                ma_free(currentSourceListNode);
                break;
            }

            parentSourceListNodePtr = &(currentSourceListNode->next);
            currentSourceListNode = currentSourceListNode->next;
        }
    }
    ma_mutex_unlock(&audioOut->sourceListLock);
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