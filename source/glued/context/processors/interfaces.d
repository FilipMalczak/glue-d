module glued.context.processors.interfaces;

import std.algorithm;
import std.traits;

import glued.stereotypes;
import glued.logging;
import glued.utils;
import glued.collections;

import glued.context.typeindex: TypeKind;
import glued.context.processors.internals;

import dejector;


class InterfaceAutobindingSingleton: Singleton {}

struct InterfaceProcessor {
    mixin CreateLogger;
    Logger log;

    void before(GluedInternals internals){
        internals.injector.bindScope!(InterfaceAutobindingSingleton)();
    }

    static bool canHandle(A)(){
        //todo reuse isObjectType from dejector
        return is(A == interface) || is(A == class);
    }

    void handle(A)(GluedInternals internals){
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

    void after(GluedInternals internals){
        import std.array;
        log.debug_.emit("Index: ", internals.inheritanceIndex);
        log.debug_.emit("Found interfaces: ", internals.inheritanceIndex.find(TypeKind.INTERFACE));
        foreach (i; internals.inheritanceIndex.find(TypeKind.INTERFACE)){
            auto impls = internals.inheritanceIndex.getImplementations(i).array;
            auto resolved = internals.injector.resolveQuery(i);
            if (!resolved.empty && resolved.front == i)
                impls ~= i;
            if (impls.empty) {
                log.warn.emit("Interface "~i~" has no known implementations");
            } else {
                if (resolved.empty && impls.length == 1){
                    log.debug_.emit("Interface "~i~" has a sole implementation "~impls[0]~", binding them");
                    internals.injector.bind(i, impls[0]);
                }
            }
            //todo add control mechanism to disable binding impl list
            auto arrayType = fullyQualifiedName!Reference~"!("~i~"[])";
            auto canResolve = internals.injector.canResolve(arrayType);
            if (!canResolve){
                auto foo(Dejector dej) {
                    auto impls = internals.inheritanceIndex.getImplementations(i);
                    Object[] instances = impls.filter!(x => dej.canResolve(x)).map!(x => nonNull(dej.get!Object(x))).array;
                    //fixme following line of log caused a segfault; just goddamn WHY ; I think it's because log is declared outside of foo scope
                    //log.dev.emit("Instances: ", instances);
                    auto result = new Reference!(Object[])(instances);
                    return result;
                }
                auto result = foo(internals.injector);
                //todo this was initially supposed to be lazy and IMO it should still be
                log.debug_.emit("Binding ", arrayType, " with an array of all known implementations of "~i~" -> ", result);
                internals.injector.bind!(InterfaceAutobindingSingleton)(arrayType, new InstanceProvider(result));
                //internals.injector.bind!(InterfaceAutobindingSingleton)(arrayType, new FunctionProvider(toDelegate(&foo)));
            }

        }
    }
}
