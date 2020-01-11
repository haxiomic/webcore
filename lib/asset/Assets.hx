package asset;


#if !macro

/**
    # Assets Macro Class

    Extend this class to use metadata

    **Supported metadata**
    - `@embedFile(path: String, ?variableName: String)`    embeds a single file into the output

    **Paths are relative to the class used**
    
**/
@:autoBuild(asset.Assets.Macro.build())
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

        // metadata to embed a single file
        var embedMetas = metas.extract('embedFile');

        var incbinLines = new Array<String>();

        for (embedMeta in embedMetas) {
            switch embedMeta.params[0] {
                case {expr: EConst(CString(path)), pos: pos}:
                    // paths are relative to this file
                    var absPath = sys.FileSystem.absolutePath(Path.join([classDir, path]));

                    var filename = Path.withoutDirectory(path);

                    var variableName = safeVariableName(
                        switch embedMeta.params[1] {
                            case {expr: EConst(CString(name)) }: name;
                            case null, _: filename;
                        }
                    );

                    var resourceId = path;
                    var fileBytes = try sys.io.File.getBytes(absPath) catch (e: Any) {
                        Context.fatalError('Failed to embed file: $e', pos);
                    }

                    // embed bytes using the haxe resource system
                    Context.addResource(resourceId, fileBytes);

                    var newFields = (macro class X {

                        static public final $variableName: haxe.io.Bytes = haxe.Resource.getBytes($v{resourceId});

                    }).fields;

                    fields = fields.concat(newFields);

                case null, _:
                    Context.error('@embedFile requires a file path string as an argument', embedMeta.pos);
            }
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