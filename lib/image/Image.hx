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

class Image {

    public var src(default, set): String;
    public var naturalWidth(default, null): Int;
    public var naturalHeight(default, null): Int;

    public function new() {
    }
    
    function set_src(v: String) {
        // @! trigger load probably
        return this.src = v;
    }

    static public function fromArrayBuffer(arrayBuffer: typedarray.ArrayBuffer) {
        
        // return https://gist.github.com/candycode/f18ae1767b2b0aba568e
    }

}

#end