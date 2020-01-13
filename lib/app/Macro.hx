package app;

#if macro
import haxe.macro.Context;
import haxe.macro.TypeTools;
import haxe.macro.Expr.TypePath;
import haxe.macro.ComplexTypeTools;
import haxe.io.Path;
using Lambda;

class Macro {

    /**
        Adds sets `AppInterface.Static.createMainApp` in the class' __init__ method
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

        var initExpr = macro @:privateAccess app.HaxeMainApp.Static.createMainApp = () -> new $localTypePath();

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
    static function addNativeCode(headerFilePath: String, implementationFilePath: String) {
        var classPosInfo = Context.getPosInfos(Context.currentPos());
        var classFilePath = Path.isAbsolute(classPosInfo.file) ? classPosInfo.file : Path.join([Sys.getCwd(), classPosInfo.file]);
        var classDir = Path.directory(classFilePath);

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

}
#end