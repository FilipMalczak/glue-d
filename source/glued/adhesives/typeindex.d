module glued.adhesives.typeindex;

import std.array;
import std.algorithm.iteration;

import glued.logging;

import glued.set;

enum TypeKind { INTERFACE, ABSTRACT_CLASS, CONCRETE_CLASS }

class InheritanceIndex {
    import std.algorithm;
    TypeKind[string] kinds;
    Set!(string)[string] implementations;
    mixin CreateLogger;
    Logger log;

    this(LogSink logSink){
        log = Logger(logSink);
    }

    override string toString(){
        import std.conv: to;
        string[] pairs;
        foreach (k; implementations.keys()){
            pairs ~= "'"~k~"': Set!string("~to!string(implementations[k].asRange.array)~")";
        }
        return typeof(this).stringof~"(kinds="~to!string(kinds)~", implementations=["~pairs.join(", ")~"])";
    }

    void markExists(string query, TypeKind kind){
        log.debug_.emit(query, " is of kind ", kind);
        if (query in kinds)
        {
            assert(kinds[query] == kind); //todo better exception
            log.debug_.emit("Checks out with previous knowledge");
        } 
        else 
        {
            kinds[query] = kind;
            log.debug_.emit("That's new knowledge");
        }
    }

    void markExtends(string extending, string extended){
        log.debug_.emit(extending, " extends ", extended);
        if (!(extended in implementations))
            implementations[extended] = Set!string();
        implementations[extended].put(extending);
    }

    TypeKind getTypeKind(string typeName){
        return TypeKind.INTERFACE;
    }

    Set!string getDirectSubtypes(string typeName){
        auto result = Set!string();
        if (typeName in implementations) {
            result.addAll(implementations[typeName].asRange);
        }
        return result;
    }

    Set!string getSubtypes(string typeName){
        auto result = Set!string();
        auto direct = getDirectSubtypes(typeName);
        auto indirect = direct.asRange.map!(d => getSubtypes(d).asRange.array).joiner;
        result.addAll(direct.asRange);
        result.addAll(indirect);
        return result;
    }

    auto getImplementations(string typeName){
        return getSubtypes(typeName).asRange.filter!(n => kinds[n] == TypeKind.CONCRETE_CLASS);
    }

    auto getDirectImplementations(string typeName){
        return getDirectSubtypes(typeName).asRange.filter!(n => kinds[n] == TypeKind.CONCRETE_CLASS);
    }

    auto find(TypeKind kind){
        return kinds.keys().filter!(x => kinds[x] == kind);
    }

}
