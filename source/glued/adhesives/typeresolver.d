module glued.adhesives.typeresolver;

import std.algorithm;
import std.array;

//todo maybe these modules should be merged? "typemeta"?
import glued.adhesives.typeindex;

import glued.utils;

import dejector;

class InterfaceResolver {
    private Dejector injector;
    private InheritanceIndex inheritanceIndex;
    
    this(Dejector injector) {
        this.injector = injector;
        inheritanceIndex = injector.get!InheritanceIndex;
    }
    
    I[] getImplementations(I)(){
        //todo I need to clean up references to queryString; I think I'll just merge dejector here, since I basically rewrote it now...
        auto result = getImplementations(queryString!I).map!(x => cast(I) x).array;
        return result;
    }
    
    Object[] getImplementations(string interfaceName){
        auto impls = inheritanceIndex.getImplementations(interfaceName);
        auto result = impls
            .filter!(x => injector.canResolve(x))
            .map!(x => nonNull(injector.get!Object(x)))
            .array;
        return result;
    }
}
