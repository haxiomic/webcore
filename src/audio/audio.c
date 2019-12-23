#include <stdio.h>
#include "./audio.h"

#ifdef HXCPP_DEBUG
    #define MA_DEBUG_OUTPUT
#endif
#define MINIAUDIO_IMPLEMENTATION
#include "./miniaudio/miniaudio.h"

/**
 * AudioDevice Implementation
 */

// called from audio thread
void AudioDevice_dataCallback(ma_device* maDevice, void* pOutput, const void* pInput, ma_uint32 frameCount) {
    printf("data_callback %u \n", frameCount);

    AudioDevice* device = (AudioDevice*) maDevice->pUserData;

    // @! we should copy out the callback pointers to minimize time with mutex held
    ma_mutex_lock(&device->sourceListLock);
    {
    }
    ma_mutex_unlock(&device->sourceListLock);

    // @! need to account for thread-safe access of source list
    // AudioSourceListNode* currentSourceListNode = device->sourceNext;
    // while (currentSourceListNode != NULL) {
    //     // currentSourceListNode->source->readFramesCallback()
    //     currentSourceListNode = currentSourceListNode->next;
    // }
}

AudioDevice* AudioDevice_create(ma_result* pResult) {
    AudioDevice* audioDevice = NULL;
    ma_device* maDevice = NULL;

    maDevice = (ma_device*)ma_malloc(sizeof(*maDevice));
    if (maDevice == NULL) {
        *pResult = MA_OUT_OF_MEMORY;
        return NULL;
    }
    ma_zero_object(maDevice);

    audioDevice = (AudioDevice*)ma_malloc(sizeof(*audioDevice));
    if (audioDevice == NULL) {
        *pResult = MA_OUT_OF_MEMORY;
        return NULL;
    }
    ma_zero_object(audioDevice);

    // initialize a miniaudio device
    ma_device_config deviceConfig;
    deviceConfig = ma_device_config_init(ma_device_type_playback);
    // deviceConfig.playback.format = sampleFormat;
    // deviceConfig.playback.channels = channelCount;
    // deviceConfig.sampleRate = sampleRate;
    deviceConfig.dataCallback = AudioDevice_dataCallback;
    deviceConfig.pUserData = NULL;

    (*pResult) = ma_device_init(NULL, &deviceConfig, maDevice);
    if ((*pResult) != MA_SUCCESS) {
        return NULL;
    }

    // setup audioDevice fields
    audioDevice->maDevice = maDevice;
    maDevice->pUserData = audioDevice;
    (*pResult) = ma_mutex_init(maDevice->pContext, &audioDevice->sourceListLock);
    if ((*pResult) != MA_SUCCESS) {
        return NULL;
    }
    
    return audioDevice;
}

void AudioDevice_destroy(AudioDevice* device) {
    if (device != NULL) {
        ma_device_uninit(device->maDevice);
        ma_mutex_uninit(&device->sourceListLock);

        ma_free(device->maDevice);
        ma_free(device);
    }
}

/**
 * ! need to account for thread safe access of source list
 */
ma_result AudioDevice_addSource(AudioDevice* device, AudioSource* source) {
    ma_result result = MA_SUCCESS;

    // create an empty list node
    AudioSourceListNode* newListNode;
    newListNode = (AudioSourceListNode*)ma_malloc(sizeof(*newListNode));
    if (newListNode == NULL) {
        return MA_OUT_OF_MEMORY;
    }
    ma_zero_object(newListNode);
    newListNode->source = source;

    ma_mutex_lock(&device->sourceListLock);
    {
        // find last next-item pointer
        AudioSourceListNode** currentSourceListNodePtr = &(device->sourceNext);
        while ((*currentSourceListNodePtr) != NULL) {
            currentSourceListNodePtr = &((*currentSourceListNodePtr)->next);
        }
        (*currentSourceListNodePtr) = newListNode;
    }
    ma_mutex_unlock(&device->sourceListLock);

    return result;
}

void AudioDevice_removeSource(AudioDevice* device, AudioSource* source) {
    ma_mutex_lock(&device->sourceListLock);
    {
        // iterate list searching for source and remove when found
        AudioSourceListNode** parentSourceListNodePtr = &(device->sourceNext);
        AudioSourceListNode* currentSourceListNode = device->sourceNext;
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
    ma_mutex_unlock(&device->sourceListLock);
}

int AudioDevice_sourceCount(AudioDevice* device) {
    int count = 0;

    ma_mutex_lock(&device->sourceListLock);
    {
        AudioSourceListNode* currentSourceListNode = device->sourceNext;
        while (currentSourceListNode != NULL) {
            count++;
            currentSourceListNode = currentSourceListNode->next;
        }
    }
    ma_mutex_unlock(&device->sourceListLock);

    return count;
}