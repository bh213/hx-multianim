package wt.base;

import haxe.Constraints;

class MapTools {

    public static function count<K,V>(m:IMap<K, V>) {
        return Lambda.count(m);
    }

    public static function equalsTo<K,V>(a:IMap<K,V>, b:IMap<K,V>) {
        var countA = 0;
        
        for (key => value in a) {
            countA++;
            if (!b.exists(key)) return false;
            if (b.get(key) != value) return false;
        }
        if (countA != count(b)) return false;
        return true;
    }
        
}