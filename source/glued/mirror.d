/**
 * Extension and publis import of the lib.
 */
module glued.mirror;

import std.traits;

public import mirror;

template import_(string module_, string name){
    mixin("import "~module_~": result="~name~";");
    alias import_=result;
}

Aggregate aggregate(string m, string n)(){
    alias mod = module_!(m);
    static foreach (Aggregate a; mod.aggregates)
        if (a.identifier == n)
            return a;
    return Aggregate.init; //todo?
}

Aggregate aggregate(A)(){
    return aggregate!(moduleName!A, A.stringof)();
}
