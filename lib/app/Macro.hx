package app;

#if macro
import haxe.macro.Context;

class Macro {

    static function generateC() {
        var localClass = Context.getLocalClass();
        var fields = Context.getBuildFields();
        // trace(fields);
        return fields;
    }

}
#end