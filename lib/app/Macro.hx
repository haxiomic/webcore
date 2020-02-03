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

        var isCpp = Context.definedValue('target.name') == 'cpp';
        
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
        var classDir = getPosDirectory(Context.currentPos());

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
        Generates a framework by copying the framework files into the hxcpp output directory and combining hxcpp binaries of different architectures into a single file to link against.
        **Currently only supports iOS frameworks**
    **/
    static function copyHaxeAppFramework() {
        var pos = Context.currentPos();

        Context.onAfterGenerate(() -> {
            var outputDirectory = getOutputDirectory();

            // copy Xcode project files to generate framework
            // using resolvePath allows user overriding
            var frameworkProjectPath = Context.resolvePath('app/ios');
            for (filename in FileSystem.readDirectory(frameworkProjectPath)) {
                var outputPath = Path.join([outputDirectory, filename]);
                // Xcode doesn't like subprojects being changed duirng a build so only copy if the file doesn't already exist
                var overwrite = false;
                copyToDirectory(Path.join([frameworkProjectPath, filename]), outputDirectory, overwrite);
            }

            // symlink device and simulator binaries and lipo together different architectures
            var binaryExtension = 'a';
            var currentBuild =
                if (Context.defined('iphoneos')) {
                    filenamePattern: ~/\b(iphoneos)\b/i,
                    type: 'device',
                }
                else if (Context.defined('iphonesim')) {
                    filenamePattern: ~/\b(iphonesim)\b/i,
                    type: 'simulator',
                }
                else {
                    throw '`-D iphone` or `-D iphonesim` is required to generate a framework';
                }

            var debugSuffix = Context.defined('DEBUGSUFFIX') ? Context.definedValue('DEBUGSUFFIX') : '-debug';
            var debugFilenamePattern = new EReg('\\b$debugSuffix\\b', 'i');

            var binaryFilenames = FileSystem.readDirectory(outputDirectory).filter(filename -> {
                if (Path.extension(filename).toLowerCase() != binaryExtension) return false;
                var isDebugFile = debugFilenamePattern.match(filename);
                return
                    currentBuild.filenamePattern.match(filename) &&
                    #if debug isDebugFile #else !isDebugFile #end;
            });

            if (binaryFilenames.length == 0) {
                Context.error('Could not find hxcpp output binary', pos);
            }

            var targetFilePath = Path.join([outputDirectory, 'lib/${currentBuild.type}/libHaxeApp.a']);

            touchDirectoryPath(Path.directory(targetFilePath));

            if (binaryFilenames.length == 1) {
                // symlink
                var command = 'ln -sf "../../${binaryFilenames[0]}" "$targetFilePath"';
                Sys.println(command);
                if (Sys.command(command) != 0) {
                    Context.error('Symbolic link failed', pos);
                }
            } else if (binaryFilenames.length > 1) {
                // lipo multiple binaries together
                var command = 'lipo ${binaryFilenames.map(f -> '"${Path.join([outputDirectory, f])}"').join(' ')} -output "$targetFilePath" -create';
                Sys.println(command);
                if (Sys.command(command) != 0) {
                    Context.error('Combing multiple archs with lipo failed', pos);
                }
            }
        });

        return Context.getBuildFields();
    }

    /**
        Copies files or directories (recursively) to a given target directory
        Files in the target directory are overwritten
        When overwriting directories, their contents are merged
    **/
    static function copyToDirectory(sourcePath: String, targetDirectoryPath: String, overwrite: Bool) {
        var filename = Path.withoutDirectory(sourcePath);
        var targetFilePath = Path.join([targetDirectoryPath, filename]);

        if (FileSystem.isDirectory(sourcePath)) {
            // touch within targetDirectoryPath
            if (!FileSystem.exists(targetFilePath)) {
                FileSystem.createDirectory(targetFilePath);
            }

            // recursive file copy
            for (filename in FileSystem.readDirectory(sourcePath)) {
                copyToDirectory(Path.join([sourcePath, filename]), targetFilePath, overwrite);
            }
        } else {
            // copy single file
            if (!overwrite && FileSystem.exists(targetFilePath)) return;
            sys.io.File.copy(sourcePath, targetFilePath);
        }
    }

    /**
        Ensures directory structure exists for a given path
        (Same behavior as mkdir -p)
        @throws Any
    **/
    static function touchDirectoryPath(path: String) {
        var directories = Path.normalize(path).split('/');
        var currentDirectories = [];
        for (directory in directories) {
            currentDirectories.push(directory);
            var currentPath = currentDirectories.join('/');
            if (currentPath == '/') continue;
            if (FileSystem.isDirectory(currentPath)) continue;
            if (!FileSystem.exists(currentPath)) {
                FileSystem.createDirectory(currentPath);
            } else {
                throw 'Could not create directory $currentPath because a file already exists at this path';
            }
        }
    }

    /**
        Return the directory of the Context's current position
        For a @:build macro, this is the directory of the haxe file it's added to
    **/
    static function getPosDirectory(pos: haxe.macro.Expr.Position) {
        var classPosInfo = Context.getPosInfos(pos);
        var classFilePath = Path.isAbsolute(classPosInfo.file) ? classPosInfo.file : Path.join([Sys.getCwd(), classPosInfo.file]);
        return Path.directory(classFilePath);
    }

    static function getOutputDirectory() {
        var outputPath = Compiler.getOutput();
        return FileSystem.isDirectory(outputPath) ? outputPath : Path.directory(outputPath);
    }

    static function executeWithCwd(cwd: String, callback: () -> Void) {
        var initialCwd = Sys.getCwd();
        Sys.setCwd(cwd);
        callback();
        Sys.setCwd(initialCwd);
    }

}

#end