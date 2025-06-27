package bh.multianim;

import bh.multianim.MultiAnimBuilder.BuilderResult;
using bh.base.MapTools;

@:allow(bh.multianim.MultiAnimBuilder)
class MultiAnimMultiResult {
    final name:Null<String>;
    final allCombos:Array<String>;
    var results:Map<String, BuilderResult> = [];
    
    public function new(name, allCombos) {
        this.name = name;
        this.allCombos = allCombos;
    }

    function addResult(result, param:Array<String>) {

        results.set(toMultiKey(param), result);
    }

    inline function keyToString(value:Any):String {
        if (Std.isOfType(value, String)) {
            return value;
        } else if (Std.isOfType(value, Int) || Std.isOfType(value, Float) || Std.isOfType(value, Bool)) {
            return Std.string(value);
        } else throw 'unknown parameter type ${value}';
        
    }
    function toMultiKey(values:Array<Any>):String {
        return values.map(keyToString).join("||");
    }


    public function updateAllText(name, newText) {
        for (key => value in results) {
            value.getUpdatable(name).updateText(newText);
        }
    }

    public function findResultByCombo(...values:Any):BuilderResult {
     if (values.length != allCombos.length) throw 'invalid number of params, expected ${allCombos.length} got ${values.length}';

     
     final multiKey = toMultiKey(values);
     final retVal = results[multiKey];
     if (retVal == null) {
        throw 'could not find result for name ${name} with combo ${values}, all combos: ${allCombos}';
     }
     else return retVal;
    }

}
