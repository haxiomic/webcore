package app;

#if macro
import haxe.macro.Context;
import haxe.macro.TypeTools;
import haxe.macro.Expr.TypePath;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Compiler;
import haxe.io.Path;
import sys.FileSystem;
using Lambda;

class Macro {

    /**
        Adds sets `HaxeAppInterface.Static.createMainApp` in the class' __init__ method
    **/
    static function makeMainApp() {
        var localClass = Context.getLocalClass().get();
        var fields = Context.getBuildFields();

        if (localClass.meta.has(':notMainApp')) return fields;

        var localTypePath: TypePath = {
            pack: localClass.pack,
            name: localClass.module.split('.').pop(),
            sub: localClass.name,
        }

        var isCpp = Context.getDefines().has('cpp');
        
        var initExpr = if (isCpp) {
            // add static constructor function
            fields = fields.concat((macro class X {
                static function __construct__(): app.HaxeAppInterface {
                    return new $localTypePath();
                }
            }).fields);
            macro @:privateAccess {
                app.HaxeApp.Static.createMainApp = cpp.Function.fromStaticFunction($i{localClass.module}.__construct__);
            };
        } else {
            macro @:privateAccess {
                app.HaxeApp.Static.createMainApp = () -> new $localTypePath();
            };
        }

        // add initExpr to __init__
        var initField = fields.find(f -> f.name == '__init__');

        if (initField != null) {
            switch initField.kind {
                case FFun(f) if (initField.access.has(AStatic)): {
                    // append initExpr
                    f.expr = macro {
                        ${f.expr};
                        $initExpr;
                    }
                }
                default:
                    Context.fatalError('Invalid __init__ field, expected static function', initField.pos);
            }
        } else {
            // add __init__ function
            fields = fields.concat((macro class X {
                static function __init__() {
                    $initExpr;
                }
            }).fields);
        }

        // add @:keep metadata because we want this class to be initialized
        localClass.meta.add(':keep', [], localClass.pos);

        return fields;
    }

    /**
        Adds :buildXml metadata that copies native interface code into the hxcpp output directory
    **/
    static function hxcppAddNativeCode(headerFilePath: String, implementationFilePath: String) {
        var classDir = getBuildClassDirectory();

        var buildXml = '
            <copy from="$classDir/$headerFilePath" to="include" />

            <files id="haxe">
                <file name="$classDir/$implementationFilePath">
                    <depend name="$classDir/$headerFilePath"/>
                </file>
            </files>
        ';

        // add @:buildXml
        Context.getLocalClass().get().meta.add(':buildXml', [macro $v{buildXml}], Context.currentPos());

        return Context.getBuildFields();
    }

    /**
        Copies a file or directory to the current compile output
    **/
    static function copyToOutput(path: String) {
        var pos = Context.currentPos();
        var sourcePath = Path.join([getBuildClassDirectory(), path]);

        // wait until compilation is complete before copying the files
        Context.onAfterGenerate(() -> {
            if (FileSystem.exists(sourcePath)) {
                copyToDirectoryOverwrite(sourcePath, Compiler.getOutput());
            } else {
                Context.fatalError('Path "$sourcePath" does not exist', pos);
            }
        });

        return Context.getBuildFields();
    }

    static function getBuildClassDirectory() {
        var classPosInfo = Context.getPosInfos(Context.currentPos());
        var classFilePath = Path.isAbsolute(classPosInfo.file) ? classPosInfo.file : Path.join([Sys.getCwd(), classPosInfo.file]);
        return Path.directory(classFilePath);
    }

    /**
        Copies files or directories (recursively) to a given target directory
        Files in the target directory are overwritten
        When overwriting directories, their contents are merged
    **/
    static function copyToDirectoryOverwrite(sourcePath: String, targetDirectoryPath: String) {
        var filename = Path.withoutDirectory(sourcePath);
        var targetFilePath = Path.join([targetDirectoryPath, filename]);

        if (FileSystem.isDirectory(sourcePath)) {

            // touch within targetDirectoryPath
            if (!FileSystem.exists(targetFilePath)) {
                FileSystem.createDirectory(targetFilePath);
            }

            // recursive file copy
            for (filename in FileSystem.readDirectory(sourcePath)) {
                copyToDirectoryOverwrite(Path.join([sourcePath, filename]), targetFilePath);
            }
        } else {
            // copy single file
            sys.io.File.copy(sourcePath, targetFilePath);
        }
    }

}
#end