ma_format_s16 is most widely supported format, should we use this over f32?
    - Yes


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