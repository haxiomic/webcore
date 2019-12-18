- ma_format_s16 is most widely supported format, should we use this over f32?
    - Yes
- avoid sample rate conversion; try to find the best sample rate for the device. This avoids crackling effect
    - "By default, the device config will use native device settings (format, channels, sample rate, etc.). Using native settings means you will get an optimized pass-through data transmission pipeline to and from the device, but you will need to do all format conversions manually."
- "Note that GCC and Clang requires "-msse2", "-mavx2", etc. for SIMD optimizations."
- "If you want to disable a specific backend, #define the appropriate MA_NO_* option before the implementation."
- "If ma_device_init() is called with a device that's not aligned to the 4 bytes on 32-bit or 8 bytes on
  64-bit it will _not_ be thread-safe. The reason for this is that it depends on members of ma_device being
  correctly aligned for atomic assignments."
- "By default miniaudio will automatically clip samples. This only applies when the playback sample format
  is configured as ma_format_f32. If you are doing clipping yourself, you can disable this overhead by
  setting noClip to true in the device config."
    -> use ma_context_enumerate_devices/ma_context_get_device_info to try to get preferred
- Verify two-channel input->output

- source.start()

- AudioDevice singleton
    - MA device init
    - Creates the audio thread
    - source.start(device?)
        var d = AudioDevice.getDefaultDevice();
        d.start(source);

f = new AudioBufferFileSource('file.mp3');
f.start();
f.stop();

Source {

    // @! called from the audio thread!
    private abstract readBytes(range?) {
        
    }

}

FileSource {

    readAll -> Buffer {
        // decoder
        // go
    }

}

@:access(source)
AudioDevice {

    start(source) {
        lock(playingSources) {
            playingSources.push(source);
        }
    }

    private dataCallback(device, outputBuffer, ...) {
        lock (playingSources) {
            for (source of playingSources) {
                source.readBytes(...);
            }
        }
    }

}

So we have the concept of a audio source

Buffer source?


File source?
    How can we play partial content / stream