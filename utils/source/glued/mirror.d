/**
 * Extension and public import of the lib.
 */
module glued.mirror;

import std.traits;

//fixme I'm starting to think that mirror is useless here
public import mirror;

template import_(string module_, string name){
    mixin("import "~module_~": result="~name~";");
    alias import_=result;
}

LocatedAggregate aggregate(string m, string n)(){
    alias mod = module_!(m);
    static foreach (Aggregate a; mod.aggregates)
        if (a.identifier == n)
            return LocatedAggregate(m, a);
    return LocatedAggregate.init; //todo?
}

LocatedAggregate aggregate(A)(){
    return aggregate!(moduleName!A, A.stringof)();
}

struct LocatedAggregate {
    string moduleName;
    Aggregate aggregate;
}
