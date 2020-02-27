package image;

/**
    Native implementation of html image
**/

#if js

import js.html.Blob;
import js.html.URL;

@:forward
abstract Image(js.html.Image) from js.html.Image to js.html.Image {

    /**
        **Asynchronously** decode an arraybuffer with the contents of a supported image file format
        Supported formats depend on the browser
    **/
    static public function decodeImageData(arrayBuffer: typedarray.ArrayBuffer, ?successCallback: Image -> Void, ?errorCallback: String -> Void): Void {
        // we don't provide an explicit mime type (like { type: 'image/jpeg' }), so we hope the browser is able to determine image type from the file header
        var blob = new Blob([(arrayBuffer: js.lib.ArrayBuffer)]);
        var objectUrl = URL.createObjectURL(blob);
        var image = new js.html.Image();

        function onError(e: Any) {
            if (errorCallback != null) {
                // usually there is no error message stored in the event
                // using image.decode().catch() may allow accessing error information
                errorCallback('Failed to decode image');
            }
            image.removeEventListener('error', onError);
        }

        function onLoad(e: Any) {
            if (successCallback != null) {
                successCallback(image);
            }
            image.removeEventListener('load', onLoad);
        }

        image.addEventListener('error', onError, true);
        image.addEventListener('load', onLoad, true);

        image.decoding = 'async';

        image.src = objectUrl;
    }

}

#else

import cpp.*;
import typedarray.ArrayBuffer;
import image.native.StbImage;

/**
    Native Implementation of HTMLImageElement
    Image data is stored internally with row packing alignment of 1 (i.e no padding bytes between rows)
**/
class Image {

    public var width: Int;
    public var height: Int;
    public var naturalWidth(default, null): Int = -1;
    public var naturalHeight(default, null): Int = -1;
    public var src(default, set): String;

    // internal image data
    var nChannels (default, null): Int = -1;
    var dataType (default, null): PixelDataType; 
    var data (default, null): Null<ArrayBuffer> = null;

    public function new(width: Int = 0, height: Int = 0) {
        this.width = width;
        this.height = height;
    }
    
    function getData(nChannels: Int, dataType: PixelDataType, flipY: Bool, forceUnpremultiply: Bool): Null<ArrayBuffer> {
        // @! todo get original file arraybuffer

        var width: Int32 = -1;
        var height: Int32 = -1;
        var nChannelsInFile: Int32 = -1;

        var bytesPerChannel = switch dataType {
            case UNSIGNED_BYTE: 1;
            case FLOAT: 4;
        }

        StbImage.stbi_set_flip_vertically_on_load(flipY ? 1 : 0);
        StbImage.stbi_set_unpremultiply_on_load(forceUnpremultiply ? 1 : 0);

        var imageBytes = switch dataType {
            case UNSIGNED_BYTE: StbImage.stbi_load_from_memory(arrayBuffer.toCPointer(), arrayBuffer.byteLength, Native.addressOf(width), Native.addressOf(height), Native.addressOf(nChannelsInFile), nChannels);
            case FLOAT: StbImage.stbi_loadf_from_memory(arrayBuffer.toCPointer(), arrayBuffer.byteLength, Native.addressOf(width), Native.addressOf(height), Native.addressOf(nChannelsInFile), nChannels);
        }
        
        var byteLength = width * height * nChannels * bytesPerChannel;

        return ArrayBuffer.fromCPointer(cast imageBytes, byteLength);
    }
    
    function set_src(v: String) {
        // @! trigger load probably
        return this.src = v;
    }

    /**
        **Asynchronously** decode an arraybuffer with the contents of a supported image file format
        See stb_image.h for supported image formats
        Error handling managed by events (`onerror`)
    **/
    static public function decodeImageData(arrayBuffer: typedarray.ArrayBuffer, ?successCallback: Image -> Void, ?errorCallback: String -> Void): Void {
        sys.thread.Thread.create(() -> {
            var width: Int32 = -1;
            var height: Int32 = -1;
            var nChannels: Int32 = -1;
            var bytesPerChannel = 1;

            var imageBytes = StbImage.stbi_load_from_memory(arrayBuffer.toCPointer(), arrayBuffer.byteLength, Native.addressOf(width), Native.addressOf(height), Native.addressOf(nChannels), 0);

            if (imageBytes == null || width == -1 || height == -1 || nChannels == -1) {
                var failureReason = StbImage.stbi_failure_reason().toString();

                if (errorCallback != null) {
                    haxe.EntryPoint.runInMainThread(() -> errorCallback('Failed to parse image buffer: $failureReason'));
                }
            } else {
                var image = new Image(width, height);
                image.naturalWidth = width;
                image.naturalHeight = height;
                image.nChannels = nChannels;
                image.dataType = UNSIGNED_BYTE;

                var byteLength = width * height * nChannels * bytesPerChannel;
                image.data = ArrayBuffer.fromCPointer(imageBytes, byteLength);

                if (successCallback != null) {
                    haxe.EntryPoint.runInMainThread(() -> successCallback(image));
                }
            }
        });
    }

}

// opengl-style image formats
enum abstract PixelDataType(Int) {
    var FLOAT;
    var UNSIGNED_BYTE;
}

#end