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
        Copies a file or directory to the current compile output
    **/
    /*
    static function copyToOutput(path: String) {
        var pos = Context.currentPos();
        var sourcePath = Path.join([getPosDirectory(pos), path]);

        // wait until compilation is complete before copying the files
        Context.onAfterGenerate(() -> {
            if (FileSystem.exists(sourcePath)) {
                copyToDirectoryOverwrite(sourcePath, getOutputDirectory());
            } else {
                Context.fatalError('Path "$sourcePath" does not exist', pos);
            }
        });

        return Context.getBuildFields();
    }
    */

    /**
        Generates a framework by copying the framework files into the hxcpp output directory and combining hxcpp binaries of different architectures into a single file to link against.
        **Currently only supports iOS frameworks**
    **/
    static function copyHaxeAppFramework() {
        var pos = Context.currentPos();
        var outputDirectory = FileSystem.absolutePath(getOutputDirectory());

        Context.onAfterGenerate(() -> {

            // copy Xcode project files to generate framework
            // using resolvePath allows user overriding
            var frameworkProjectPath = FileSystem.absolutePath(Context.resolvePath('app/ios'));
            for (filename in FileSystem.readDirectory(frameworkProjectPath)) {
                copyToDirectoryOverwrite(Path.join([frameworkProjectPath, filename]), outputDirectory);
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

            var binaries = FileSystem.readDirectory(outputDirectory).filter(filename -> {
                if (Path.extension(filename).toLowerCase() != binaryExtension) return false;
                var isDebugFile = debugFilenamePattern.match(filename);
                return
                    currentBuild.filenamePattern.match(filename) &&
                    #if debug isDebugFile #else !isDebugFile #end;
            }).map(filename -> Path.join([outputDirectory, filename]));

            var targetFilePath = Path.join([outputDirectory, 'lib/${currentBuild.type}/libHaxeApp.a']);

            touchDirectoryPath(Path.directory(targetFilePath));

            if (binaries.length == 1) {
                // symlink
                var command = 'ln -sf "${binaries[0]}" "$targetFilePath"';
                Sys.println(command);
                if (Sys.command(command) != 0) {
                    Context.error('Symbolic link failed', pos);
                }
            } else if (binaries.length > 1) {
                // lipo multiple binaries together
                throw '@! todo: lipo multiple binaries together';
            }



            // @! copy files method doesn't work becuse we still need a bridging header
            // var frameworkSourcePath = Context.resolvePath('app/ios/HaxeAppFramework');

            // copy framework method is best but requires lipo
            // compile framework doesn't work well because it's hard to create a universal framework
            
            /*
            var outputDirectoryFiles = FileSystem.readDirectory(outputDirectory);
            
            // for ios we merge all architectures to a single file with the lipo tool
            // this makes it easy for the Xcode project to link to the hxcpp generated binaries
            if (Context.defined('iphone') || Context.defined('iphonesim')) {
                var iphoneosFilenamePattern = ~/\b(iphoneos|iphonesim)\b/i;

                var debugSuffix = Context.defined('DEBUGSUFFIX') ? Context.definedValue('DEBUGSUFFIX') : '-debug';
                var debugFilenamePattern = new EReg('\\b$debugSuffix\\b', 'i');

                var iphoneosArchiveFilenames = outputDirectoryFiles.filter(
                    filename -> {
                        if (Path.extension(filename).toLowerCase() != 'a') return false;
                        var isDebugFile = debugFilenamePattern.match(filename);
                        var isIPhoneOsFile = iphoneosFilenamePattern.match(filename);
                        return
                            isIPhoneOsFile &&
                            #if debug isDebugFile #else !isDebugFile #end;
                    }
                );

                var iphoneosArchivePaths = iphoneosArchiveFilenames.map(f -> Path.join([outputDirectory, f]));

                var derivedDataPath = Path.join([outputDirectory, 'framework-build']);
                touchDirectoryPath(derivedDataPath);

                var combinedArchivePath = Path.join([derivedDataPath, 'libCombinedArchive.a']);


                var lipoCommand = 'lipo ${iphoneosArchivePaths.map(p -> '"$p"').join(' ')} -output "${combinedArchivePath}" -create';
                Sys.println(lipoCommand);
                var exitCode = Sys.command(lipoCommand);
                if (exitCode != 0) {
                    Context.error('Failed to create combined archive with lipo. Exit code $exitCode', pos);
                }

                //@! handle IPHONE_VER

                // compile the Xcode project to generate a framework
                // users can override the xcode project by redefine the path class-path app/ios
                var xcodeProjectPath = FileSystem.absolutePath(Context.resolvePath('app/ios'));

                executeWithCwd(xcodeProjectPath, () -> {
                    var scheme = 'HaxeAppFramework';

                    // to solve the framework archiecture issue
                    // See https://stackoverflow.com/questions/51558933/error-unable-to-load-standard-library-for-target-arm64-apple-ios10-0-simulator
                    // need to be careful not to have simulator framework code for app store submission
                    // https://stackoverflow.com/questions/29634466/how-to-export-fat-cocoa-touch-framework-for-simulator-and-device

                    // For build settings variables see https://developer.apple.com/library/archive/documentation/DeveloperTools/Reference/XcodeBuildSettingRef/1-Build_Setting_Reference/build_setting_ref.html
                    var command = 'xcodebuild ' + [
                        // 'LIBRARY_SEARCH_PATHS="$outputDirectory"',
                        'CONFIGURATION_BUILD_DIR="$outputDirectory"',
                        'OTHER_LDFLAGS="$combinedArchivePath"',
                        '-derivedDataPath "$derivedDataPath"',
                        '-scheme $scheme',
                        'archive'
                    ].join(' ');

                    Sys.println(command);
                    var exitCode = Sys.command(command);
                    if (exitCode != 0) {
                        Context.error('Failed to compile xcode framework project. Exit code $exitCode', pos);
                    }
                });
            }
            */
        });

        return Context.getBuildFields();
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