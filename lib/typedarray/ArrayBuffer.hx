package typedarray;

#if js

// in js, we abstract over ArrayBuffer so we can enable to/from haxe.io.Bytes
@:forward
abstract ArrayBuffer(js.lib.ArrayBuffer) to js.lib.ArrayBuffer from js.lib.ArrayBuffer {

	@:to inline function toBytes(): haxe.io.Bytes {
		return haxe.io.Bytes.ofData(this);
	}

	@:from static inline function fromBytes(bytes: haxe.io.Bytes): ArrayBuffer {
		// in js BytesData is ArrayBuffer
		return bytes.getData();
	}

}

#else

@:nullSafety
abstract ArrayBuffer(haxe.io.Bytes) from haxe.io.Bytes to haxe.io.Bytes {

	public var byteLength (get, never): Int;
	
	@:pure
	public inline function new(length: Int) {
		this = haxe.io.Bytes.alloc(length);
	}

	/**
		Returns a new ArrayBuffer whose contents are a copy of this ArrayBuffer's bytes from start, inclusive, up to end, exclusive. If either begin or end is negative, it refers to an index from the end of the array, as opposed to from the beginning.
	**/
	@:pure
	public function slice(start: Int, ?end: Int): ArrayBuffer {
		final lastIndex = this.length - 1;

		if (end == null) end = this.length;
		if (start < 0) start = this.length + start;
		if (end < 0) end = this.length + end;

		end = imin(imax(end, 0), this.length);
		start = imin(imax(start, 0), lastIndex);

		var copyLength = imax(end - start, 0);

		var copy: haxe.io.Bytes = new ArrayBuffer(copyLength);
		copy.blit(0, this, start, copyLength);

		return copy;
	}

	#if cpp
	@:pure
	public inline function toCPointer(): cpp.Star<cpp.UInt8> {
		return cast cpp.NativeArray.address(this.getData(), 0).raw;
	}
	#end

	@:pure inline function imax(a: Int, b: Int) return a > b ? a : b;
	@:pure inline function imin(a: Int, b: Int) return a < b ? a : b;

	@:pure inline function get_byteLength(): Int {
		return this.length;
	}

	static public inline function isView(value: Dynamic): Bool {
		return Std.is(value, ArrayBufferView.ArrayBufferViewBase);
	}

	@:from
	static public inline function ofData(bytesData: haxe.io.BytesData): ArrayBuffer {
		return haxe.io.Bytes.ofData(bytesData);
	}

	#if cpp
	/**
		After calling this the return ArrayBuffer **does not** take responsibility for freeing the internal memory
	**/
	static public inline function fromCPointer(cPointer: cpp.Star<cpp.UInt8>, byteLength: Int): ArrayBuffer {
		return ofData(cpp.Pointer.fromStar(cPointer).toUnmanagedArray(byteLength));
	}
	#end

}

#end
