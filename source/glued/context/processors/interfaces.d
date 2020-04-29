module glued.context.processors.interfaces;

import std.array;
import std.algorithm;
import std.traits;

import glued.stereotypes;
import glued.logging;
import glued.utils;
import glued.set;

import glued.context.typeindex: InheritanceIndex, TypeKind;
import glued.context.processors.api;

import dejector;

class InterfaceResolver {
    mixin CreateLogger;
    Logger log;
    
    private Dejector dejector;
    
    this(Dejector dejector) {
        this.dejector = dejector;
    }
    
    I[] getImplementations(I)(){
        //todo I need to clean up references to queryString; I think I'll just merge dejector here, since I basically rewrote it now...
        auto result = getImplementations(queryString!I).map!(x => cast(I) x).array;
        return result;
    }
    
    Object[] getImplementations(string interfaceName){
        auto impls = inheritanceIndex.getImplementations(interfaceName);
        //fixme following line of log caused a segfault; just goddamn WHY ; I think it's because log is declared outside of foo scope
        //log.dev.emit("Instances: ", instances);
        auto result = impls
            .filter!(x => dejector.canResolve(x))
            .map!(x => nonNull(dejector.get!Object(x)))
            .array;
        return result;
    }
    
    @property
    private InheritanceIndex inheritanceIndex(){
        return dejector.get!InheritanceIndex;
    }
}

class InterfaceProcessor: Processor {
    mixin RequiredProcessorCode;

    void beforeScan(GluedInternals internals){
        //todo dejector has canResolve(string), but no canResolve(T)()
        //todo this should be onContextInit
        if (internals.injector.resolveQuery!InterfaceResolver().empty) {
            log.info.emit("Binding InterfaceResolver");
            internals.injector.bind!InterfaceResolver;
        }
    }

    static bool canHandle(A)(){
        //todo reuse isObjectType from dejector
        return is(A == interface) || is(A == class);
    }

    void handle(A)(GluedInternals internals){
        static if (canHandle!A()){ //todo log about it
            immutable key = fullyQualifiedName!A; //todo queryString?
            log.debug_.emit("Handling ", key);
            static if (is(A == interface)){
                immutable kind = TypeKind.INTERFACE;
            } else {
                static if (__traits(isAbstractClass, A))
                    immutable kind = TypeKind.ABSTRACT_CLASS;
                else
                    immutable kind = TypeKind.CONCRETE_CLASS;
            }
            log.debug_.emit("Kind: ", kind);
            internals.inheritanceIndex.markExists(key, kind);
            import std.traits;
            static foreach (b; BaseTypeTuple!A){
                static if (!is(b == Object)){
                    //todo ditto
                    log.trace.emit(fullyQualifiedName!A, " extends ", fullyQualifiedName!b);
                    internals.inheritanceIndex.markExtends(fullyQualifiedName!A, fullyQualifiedName!b);
                    handle!(b)(internals);
                }
            }
        }
    }

    void afterScan(GluedInternals internals){}
    
    void onContextFreeze(GluedInternals internals){
        log.debug_.emit("Trying to bind interfaces");
        foreach (i; internals.inheritanceIndex.find(TypeKind.INTERFACE)){
            auto impls = internals.inheritanceIndex.getImplementations(i).array;
            if (impls.length == 1){
                log.debug_.emit("Binding interface ", i, " with sole implementation ", impls[0]);
                internals.injector.bind(i, impls[0]);
            } else {
                if (impls.length == 0){ //todo turn off somehow; by log level, or maybe by dedicated config entry?
                    log.warn.emit("Interface ", i, " has no implementation in current context!");
                }
            }
        }
    }
}
