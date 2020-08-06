package wc.image;

#if js

import js.html.Blob;
import js.html.URL;
import wc.typedarray.ArrayBuffer;

/**
    HTMLImageElement extended to add `decodeImageData()`
**/
@:forward
abstract Image(js.html.Image) from js.html.Image to js.html.Image {

    /**
        **Asynchronously** decode an arraybuffer with the contents of a supported image file format
        `internalFormatHint` is used for native targets and is ignored for js
        Supported formats depend on the browser
    **/
    static public function decodeImageData(arrayBuffer: ArrayBuffer, ?successCallback: Image -> Void, ?errorCallback: String -> Void, ?internalFormatHint: InternalFormatHint): Void {
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
import wc.typedarray.ArrayBuffer;
import image.native.StbImage;

/**
    Native Implementation of HTMLImageElement
    Pixel data is always tightly packed; in OpenGL terms the packing alignment is 1
    Uses stb_image.h
**/
class Image {

    public var width: Int;
    public var height: Int;
    public var naturalWidth(default, null): Int = -1;
    public var naturalHeight(default, null): Int = -1;

    // @! todo: we need events before we can enable loading from a `src` path
    // public var src(default, set): String;

    // internal image data
    var sourceFileBytes: Null<ArrayBuffer> = null;

    var cachedPixelData(default, set): Null<{
        final pixelsCPointer: Star<cpp.Void>;
        final pixels: ArrayBuffer;
        final nChannels: Int;
        final dataType: PixelDataType;
        final flipY: Bool;
        final forceUnpremultiply: Bool;
    }> = null;

    public function new(width: Int = 0, height: Int = 0) {
        this.width = width;
        this.height = height;

        #if cpp
        cpp.vm.Gc.setFinalizer(this, cpp.Function.fromStaticFunction(finalizer));
        #end
    }

    /**
        Will also free stbi allocated pixel data in the cache
    **/
    function clearInternalState() {
        naturalWidth = 0;
        naturalHeight = 0;
        sourceFileBytes = null;
        cachedPixelData = null;
    }
    
    /**
        Returns a tightly packed buffer of pixels given format requirements
        @throws String if parsing the original file fails
    **/
    function getData(nChannels: Int, dataType: PixelDataType, flipY: Bool, forceUnpremultiply: Bool): Null<ArrayBuffer> {
        if (cachedPixelData != null &&
            cachedPixelData.nChannels == nChannels &&
            cachedPixelData.dataType == dataType &&
            cachedPixelData.flipY == flipY &&
            cachedPixelData.forceUnpremultiply == forceUnpremultiply
        ) {
            return cachedPixelData.pixels;
        }

        if (sourceFileBytes == null) {
            return null;
        }

        // #if debug
        if (cachedPixelData != null) {
            trace([
                    'Warning: pixel format requested that does not match the internal format; reformatting is required',
                    '   Requested:',
                    '       nChannels: $nChannels, dataType: $dataType, flipY: $flipY, forceUnpremultiply: $forceUnpremultiply',
                    '   Cached:',
                    '       nChannels: ${cachedPixelData.nChannels}, dataType: ${cachedPixelData.dataType}, flipY: ${cachedPixelData.flipY}, forceUnpremultiply: ${cachedPixelData.forceUnpremultiply}',
            ].join('\n'));
        }
        // #end

        var width: Int32 = -1;
        var height: Int32 = -1;
        var nChannelsInFile: Int32 = -1;

        var bytesPerChannel = switch dataType {
            case UNSIGNED_BYTE: 1;
            case FLOAT: 4;
        }

        StbImage.stbi_set_flip_vertically_on_load(flipY ? 1 : 0);
        StbImage.stbi_set_unpremultiply_on_load(forceUnpremultiply ? 1 : 0);

        var imageBytes: Star<cpp.Void> = switch dataType {
            case UNSIGNED_BYTE: cast StbImage.stbi_load_from_memory(sourceFileBytes.toCPointer(), sourceFileBytes.byteLength, Native.addressOf(width), Native.addressOf(height), Native.addressOf(nChannelsInFile), nChannels);
            case FLOAT: cast StbImage.stbi_loadf_from_memory(sourceFileBytes.toCPointer(), sourceFileBytes.byteLength, Native.addressOf(width), Native.addressOf(height), Native.addressOf(nChannelsInFile), nChannels);
        }

        if (imageBytes == null || width == -1 || height == -1 || nChannels == -1) {
            var failureReason = StbImage.stbi_failure_reason().toString();

            throw 'Failed to parse image buffer: $failureReason';
        }
        
        var byteLength = width * height * nChannels * bytesPerChannel;

        var pixelData = ArrayBuffer.fromCPointer(cast imageBytes, byteLength);

        cachedPixelData = {
            pixelsCPointer: imageBytes,
            pixels: pixelData,
            nChannels: nChannels,
            dataType: dataType,
            flipY: flipY,
            forceUnpremultiply: forceUnpremultiply,
        }

        return pixelData;
    }
    
    // function set_src(v: String) {
    //     clearInternalState();
    //     // load file from filesystem
    //     return this.src = v;
    // }

    function set_cachedPixelData(v) {
        // free the cached StbImage allocated pixel buffer
        if (this.cachedPixelData != null) {
            StbImage.stbi_image_free(this.cachedPixelData.pixelsCPointer);
        }
        return this.cachedPixelData = v;
    }

    /**
        **Asynchronously** decode an arraybuffer with the contents of a supported image file format

        `internalFormatHint` is used to specify how the pixel data is formatted internally. If pixel data of a different format is required then expensive synchronous reformatting is required. To avoid this, provide details of the expected format.
        For example: if when passing the image to `texImage2DImageSource` in WebGL format and type are RGBA and UNSIGNED_BYTE, then pass
            `{ nChannels: 4, dataType: UNSIGNED_BYTE }`

        By default, `internalFormatHint` is
            `{ nChannels: <matches source file>, dataType: > 8 bits-per-channel ? FLOAT : UNSIGNED_BYTE }`

        Use `-D debug` to receive warnings when reformatting occurs
        
        See stb_image.h for supported image formats
    **/
    static public function decodeImageData(imageFileBytes: ArrayBuffer, ?successCallback: Image -> Void, ?errorCallback: String -> Void, ?internalFormatHint: InternalFormatHint): Void {
        sys.thread.Thread.create(() -> {
            var width: Int32 = -1;
            var height: Int32 = -1;
            var nChannels: Int32 = -1;

            var result = StbImage.stbi_info_from_memory(imageFileBytes.toCPointer(), imageFileBytes.byteLength, Native.addressOf(width), Native.addressOf(height), Native.addressOf(nChannels)) > 0;

            if (!result || width == -1 || height == -1 || nChannels == -1) {
                var failureReason = StbImage.stbi_failure_reason().toString();

                if (errorCallback != null) {
                    haxe.EntryPoint.runInMainThread(() -> errorCallback('Failed to parse image buffer: $failureReason'));
                }
            } else {
                var is16Bit = StbImage.stbi_is_16_bit_from_memory(imageFileBytes.toCPointer(), imageFileBytes.byteLength) > 0;

                var image = new Image(width, height);
                image.naturalWidth = width;
                image.naturalHeight = height;
                image.sourceFileBytes = imageFileBytes;

                internalFormatHint = internalFormatHint == null ? {} : internalFormatHint;
                
                // synchronously decode the image file and cache it internally
                image.getData(
                    internalFormatHint.nChannels != null ? internalFormatHint.nChannels : nChannels,
                    internalFormatHint.dataType != null ? internalFormatHint.dataType : (is16Bit ? FLOAT : UNSIGNED_BYTE),
                    internalFormatHint.flipY != null ? internalFormatHint.flipY : false,
                    internalFormatHint.forceUnpremultiply != null ? internalFormatHint.forceUnpremultiply : false
                );

                if (successCallback != null) {
                    haxe.EntryPoint.runInMainThread(() -> successCallback(image));
                }
            }
        });
    }

    static function finalizer(instance: Image) {
        #if debug
        Stdio.printf("%s\n", "[debug] Image.finalizer()");
        #end
        instance.clearInternalState();
    }

}

#end

/**
    OpenGL-style image formats
**/
enum abstract PixelDataType(Int) {
    var FLOAT;
    var UNSIGNED_BYTE;
}

/**
    Internal pixel format hint for async decode
**/
typedef InternalFormatHint = {
    ?nChannels: Int,
    ?dataType: PixelDataType,
    ?flipY: Bool,
    ?forceUnpremultiply: Bool,
}