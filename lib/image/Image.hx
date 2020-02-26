package image;

/**
    Native implementation of html image
**/

#if js

@:forward
abstract Image(js.html.Image) from js.html.Image to js.html.Image {

    static public function fromArrayBuffer(arrayBuffer: typedarray.ArrayBuffer) {
        // return https://gist.github.com/candycode/f18ae1767b2b0aba568e
    }

}

#else

import cpp.*;
import typedarray.ArrayBuffer;
import image.native.StbImage;

class Image {

    // public var src(default, set): String;
    public var naturalWidth(default, null): Int = -1;
    public var naturalHeight(default, null): Int = -1;

    var nChannels: Int = -1;
    var imageData: ArrayBuffer;

    public function new() {
    }
    
    // function set_src(v: String) {
    //     // @! trigger load probably
    //     return this.src = v;
    // }

    /**
        @throws string If error during parsing
    **/
    static public function fromArrayBuffer(arrayBuffer: ArrayBuffer): Image {
        // @! run on separate thread?
        var width: Int32 = -1;
        var height: Int32 = -1;
        var nChannels: Int32 = -1;

        var imageBytes = StbImage.stbi_load_from_memory(arrayBuffer.toCPointer(), arrayBuffer.byteLength, Native.addressOf(width), Native.addressOf(height), Native.addressOf(nChannels), 0);

        if (imageBytes == null || width == -1 || height == -1 || nChannels == -1) {
            var failureReason = StbImage.stbi_failure_reason().toString();
            throw 'Failed to parse image buffer: $failureReason';
        }

        var image = new Image();
        image.naturalWidth = width;
        image.naturalHeight = height;
        image.nChannels = nChannels;

        // @! convert imageBytes
        var byteLength = width * height * nChannels;
        image.imageData = ArrayBuffer.fromCPointer(imageBytes, byteLength);

        return image;
    }

}

#end