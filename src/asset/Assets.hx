package asset;


#if !macro
import haxe.io.Bytes;

/**
    Assets Macro Class

    **Supported metadata**
    - `@embedFile(path: String, ?variableName: String)`    embeds a single file into the output
    
**/
@:build(asset.Assets.Macro.build())
@embedFile('../assets/my-triangle.mp3')
class Assets {

}

#else

import haxe.io.Path;
import haxe.macro.Context;

class Macro {

    static function build() {
        var localClass = Context.getLocalClass().get();
        var classPosInfo = Context.getPosInfos(Context.currentPos());
        var classFilePath = sys.FileSystem.absolutePath(Context.resolvePath(classPosInfo.file));
        var classDir = Path.directory(classFilePath);
        var fields = Context.getBuildFields();
        var metas = localClass.meta;
        
        // single file embeds
        var embedMetas = metas.extract('embedFile');

        var incbinLines = new Array<String>();

        for (embedMeta in embedMetas) {
            switch embedMeta.params[0] {
                case {expr: EConst(CString(path)), pos: pos}:
                    var absPath = sys.FileSystem.absolutePath(Context.resolvePath(path));

                    var filename = Path.withoutDirectory(path);

                    var variableName = safeVariableName(
                        switch embedMeta.params[1] {
                            case {expr: EConst(CString(name)) }: name;
                            case null, _: filename;
                        }
                    );

                    switch Context.getDefines().get('target.name') {
                        case 'cpp':
                            // add INCBIN() file embed directive
                            // using INCBIN is faster than generating a haxe file with a byte string but that would work too
                            incbinLines.push('INCBIN($variableName, "$absPath");');
                            var dataIdent = 'g${variableName}Data'; // const unsigned char
                            var endIdent = 'g${variableName}End'; // const unsigned char - a marker to the end, take the address to get the ending pointer
                            var sizeIdent = 'g${variableName}Size'; // const unsigned int
                            var initializeVariableName = '__initialize_$variableName';

                            // wrap raw bytes in a haxe Bytes object
                            var newFields = (macro class X {

                                static public final $variableName: haxe.io.Bytes = $i{initializeVariableName}();
                                static private inline function $initializeVariableName() {
                                    var bytesData = new haxe.io.BytesData();
                                    cpp.NativeArray.setUnmanagedData(bytesData, cpp.ConstPointer.fromStar(untyped __global__.$dataIdent), untyped __global__.$sizeIdent);
                                    return haxe.io.Bytes.ofData(bytesData);
                                }

                            }).fields;

                            fields = fields.concat(newFields);

                        case 'js':
                            var bytes = sys.io.File.getBytes(absPath);
                            var base64 = haxe.crypto.Base64.encode(bytes);

                            var newFields = (macro class X {

                                static public final $variableName: haxe.io.Bytes = haxe.crypto.Base64.decode($v{base64});

                            }).fields;

                            fields = fields.concat(newFields);

                        case null, _:
                    }

                case null, _:
                    Context.error('@embedFile requires a file path string as an argument', embedMeta.pos);
            }
        }

        if (incbinLines.length > 0) {
            var str = '#include "${Path.join([classDir, 'incbin.h'])}"' + '\n' + incbinLines.join('\n');
            localClass.meta.add(':cppFileCode', [macro $v{str} ], localClass.pos);
        }

        return fields;
    }

    static function safeVariableName(str: String) {
        // replace non-ascii characters with '_'
        var wordCharacters = ~/[^\w]/g.replace(str, '_');
        // make sure it starts with a-z
        if (!~/[a-z]/i.match(wordCharacters.charAt(0))) {
            wordCharacters = '_' + wordCharacters;
        }
        return wordCharacters;
    }

}

#end