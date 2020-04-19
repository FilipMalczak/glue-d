module glued.context.typeindex;

import glued.collections;
import glued.logging;

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
        return typeof(this).stringof~"(kinds="~to!string(kinds)~", implementations="~to!string(implementations)~")";
    }

    void markExists(string query, TypeKind kind){
        log.debug_.emit(query, " is of kind ", kind);
        if (query in kinds){
            assert(kinds[query] == kind); //todo better exception
            log.debug_.emit("Checks out with previous knowledge");
        } else {
            kinds[query] = kind;
            log.debug_.emit("That's new knowledge");
        }
    }

    void markExtends(string extending, string extended){
        log.debug_.emit(extending, " extends ", extended);
        if (!(extended in implementations))
            implementations[extended] = Set!string();
        log.debug_.emit(extending, " extends ", extended, " ; ", implementations[extended]);
        implementations[extended] ~= extending;
    }

    TypeKind getTypeKind(string typeName){
        return TypeKind.INTERFACE;
    }

    auto getDirectSubtypes(string typeName){
        if (typeName in implementations)
            return implementations[typeName];
        return Set!(string)();
    }

    Set!string getSubtypes(string typeName){
        auto direct = getDirectSubtypes(typeName);
        return direct ~ (direct.empty? [] : direct.map!(d => getSubtypes(d)).fold!((x, y) => x~y).array);
    }

    auto getImplementations(string typeName){
        return getSubtypes(typeName).filter!(n => kinds[n] == TypeKind.CONCRETE_CLASS);
    }

    auto getDirectImplementations(string typeName){
        return getDirectSubtypes(typeName).filter!(n => kinds[n] == TypeKind.CONCRETE_CLASS);
    }

    auto find(TypeKind kind){
        import std.range;
        import std.traits;
        enum isRangeOf(R, T) = isInputRange!T && is(ReturnType!((R r) => r.front()): T);
        return kinds.keys().filter!(x => kinds[x] == kind);
    }

}
