package app;

#if macro
import haxe.macro.Context;
import haxe.macro.TypeTools;
import haxe.macro.Expr.TypePath;
import haxe.macro.ComplexTypeTools;
using Lambda;

class Macro {

    /**
        Adds `HaxeNativeBridge.setCreateAppCallback` to __init__ method
    **/
    static function addAppInitialization() {
        var localClass = Context.getLocalClass().get();
        var fields = Context.getBuildFields();

        var localTypePath: TypePath = {
            pack: localClass.pack,
            name: localClass.module,
            sub: localClass.name,
        }

        var initExpr = macro app.HaxeNativeBridge.setCreateAppCallback(() -> new $localTypePath());

        // add __init__ function if we don't have one already
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

        return fields;
    }

    static function generateC() {
        var localClass = Context.getLocalClass();
        var fields = Context.getBuildFields();
        // trace(fields);
        return fields;
    }

}
#end