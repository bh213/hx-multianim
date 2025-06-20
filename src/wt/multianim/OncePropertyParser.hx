package wt.multianim;

class OncePropertyParser {
    var valueMap:Map<String, Dynamic>;
    final parameterExistsError:(String)->Void;

    public function new(parameterExistsError) {
        valueMap = [];        
        this.parameterExistsError = parameterExistsError;
    }

    public function parsed(name:String) {
        if(valueMap.exists(name)) parameterExistsError(name);
        valueMap.set(name, true);
    }
}