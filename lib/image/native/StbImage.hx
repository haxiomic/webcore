package image.native;

import cpp.*;

@:include('./stb_image.h')
@:sourceFile('./native.c')
extern class StbImage {

    @:native('stbi_image_free')
    static function stbi_image_free(retval_from_stbi_load: Star<cpp.Void>): Void;

    ////////////////////////////////////
    //
    // 8-bits-per-channel interface
    //

    @:native('stbi_load_from_memory')
    static function stbi_load_from_memory(buffer: ConstStar<UInt8>, len: Int32, x: Star<Int32>, y: Star<Int32>, channels_in_file: Star<Int32>, desired_channels: Int32): Star<UInt8>;

    @:native('stbi_load_from_callbacks')
    static function stbi_load_from_callbacks(callbacks: ConstStar<NativeStbiIoCallbacks>, user: Star<cpp.Void>, x: Star<Int32>, y: Star<Int32>, channels_in_file: Star<Int32>, desired_channels: Int32): Star<UInt8>;
    
    ////////////////////////////////////
    //
    // 16-bits-per-channel interface
    //

    @:native('stbi_load_16_from_memory')
    static function stbi_load_16_from_memory(buffer: ConstStar<UInt8>, len: Int32, x: Star<Int32>, y: Star<Int32>, channels_in_file: Star<Int32>, desired_channels: Int32): Star<UInt16>;

    @:native('stbi_load_16_from_callbacks')
    static function stbi_load_16_from_callbacks(callbacks: ConstStar<NativeStbiIoCallbacks>, user: Star<cpp.Void>, x: Star<Int32>, y: Star<Int32>, channels_in_file: Star<Int32>, desired_channels: Int32): Star<UInt16>;

    ////////////////////////////////////
    //
    // float-per-channel interface
    //

    @:native('stbi_loadf_from_memory')
    static function stbi_loadf_from_memory(buffer: ConstStar<UInt8>, len: Int32, x: Star<Int32>, y: Star<Int32>, channels_in_file: Star<Int32>, desired_channels: Int32): Star<Float32>;

    @:native('stbi_loadf_from_callbacks')
    static function stbi_loadf_from_callbacks(callbacks: ConstStar<NativeStbiIoCallbacks>, user: Star<cpp.Void>, x: Star<Int32>, y: Star<Int32>, channels_in_file: Star<Int32>, desired_channels: Int32): Star<Float32>;
    
    ////////////////////////////////////

    @:native('stbi_info_from_memory')
    static function stbi_info_from_memory(buffer: ConstStar<UInt8>, len: Int32, x: Star<Int32>, y: Star<Int32>, comp: Star<Int32>): Int32;
    
    @:native('stbi_info_from_callbacks')
    static function stbi_info_from_callbacks(callbacks: ConstStar<NativeStbiIoCallbacks>, user: Star<cpp.Void>, x: Star<Int32>, y: Star<Int32>, comp: Star<Int32>): Int32;

    @:native('stbi_is_16_bit_from_memory')
    static function stbi_is_16_bit_from_memory(buffer: ConstStar<UInt8>, len: Int32): Int32;

    @:native('stbi_is_16_bit_from_callbacks')
    static function stbi_is_16_bit_from_callbacks(callbacks: ConstStar<NativeStbiIoCallbacks>, user: Star<cpp.Void>): Int32;
    
    /**
        flip the image vertically, so the first pixel in the output array is the bottom left
    **/
    @:native('stbi_set_flip_vertically_on_load')
    static function stbi_set_flip_vertically_on_load(flag_true_if_should_flip: Int32): Void;

    /**
        for image formats that explicitly notate that they have premultiplied alpha,
        we just return the colors as stored in the file. set this flag to force
        unpremultiplication. results are undefined if the unpremultiply overflow.
    **/
    @:native('stbi_set_unpremultiply_on_load')
    static function stbi_set_unpremultiply_on_load(flag_true_if_should_unpremultiply: Int32): Void;


    @:native('stbi_failure_reason')
    static function stbi_failure_reason(): ConstCharStar;

}

typedef ReadCallback = Callable<(user: Star<cpp.Void>, data: Star<Char>, size: Int32) -> Int32>;
typedef SkipCallback = Callable<(user: Star<cpp.Void>, n: Int32) -> Void>;
typedef EofCallback = Callable<(user: Star<cpp.Void>) -> Int32>;

/**
    Extern for `stbi_io_callbacks`
    Instances of this type are not garbage collected; manually call instance.free()
**/
@:include('./stb_image.h')
@:sourceFile('./native.c')
@:native('stbi_io_callbacks')
@:unreflective
@:structAccess
extern class NativeStbiIoCallbacks {
    
    /**
        fill 'data' with 'size' bytes.  return number of bytes actually read
    **/
    var read: ReadCallback;

    /**
        skip the next 'n' bytes, or 'unget' the last -n bytes if negative
    **/
    var skip: SkipCallback;

    /**
        returns nonzero if we are at end of file/data
    **/
    var eof: EofCallback;

    @:native('~stbi_io_callbacks')
    function free(): Void;

    @:native('new stbi_io_callbacks')
    static function alloc(): Star<NativeStbiIoCallbacks>;

    static inline function create(read: ReadCallback, skip: SkipCallback, eof: EofCallback): Star<NativeStbiIoCallbacks> {
        var instance = alloc();
        instance.read = read;
        instance.skip = skip;
        instance.eof = eof;
        return instance;
    }

}