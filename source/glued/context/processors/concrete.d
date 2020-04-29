module glued.context.processors.concrete;

import glued.stereotypes;
import glued.logging;

import glued.context.processors.api;
import glued.context.di.providers;
import glued.context.di.annotations;

import dejector;

class ConcreteTypesProcessor: Processor {
    mixin RequiredProcessorCode;

    void before(GluedInternals internals){}

    static bool canHandle(A)(){
        return is(A == class) && (isMarkedAsStereotype!(A, Component) || isMarkedAsStereotype!(A, Configuration) );
    }

    void handle(A)(GluedInternals internals){
        static if (canHandle!A()) { //todo log about it
            static if (isMarkedAsStereotype!(A, Component)) {
                import std.traits;
                log.info.emit("Binding ", fullyQualifiedName!A);
                internals.injector.bind!(A)(new ComponentClassProvider!A(log.logSink));
                log.info.emit("Bound ", fullyQualifiedName!A, " based on its class definition");
            }
            static if (isMarkedAsStereotype!(A, Configuration)){
                import std.traits;
                log.info.emit("Binding based on configuration ", fullyQualifiedName!A);
                internals.injector.bind!(A, Singleton)(new ComponentClassProvider!A(log.logSink));
                A a;
                static foreach (name; __traits(allMembers, A)){
                    static if (__traits(getProtection, __traits(getMember, A, name)) == "public" &&
                    isFunction!(__traits(getMember, A, name))) {
                        static foreach (i, overload; __traits(getOverloads, A, name)) {
                            static if (hasAnnotation!(overload, Component)) {
                                static if (!hasAnnotation!(overload, IgnoreResultBinding)){
                                    //todo reuse the same provider for many bindings
                                    log.info.emit("Binding type "~fullyQualifiedName!(ReturnType!overload)~" with method ", fullyQualifiedName!A, ".", name, "[#", i, "]");
                                    internals.injector.bind!(ReturnType!overload)(new ConfigurationMethodProvider!(A, name, i)(log.logSink));
                                    log.info.emit("Bound "~fullyQualifiedName!(ReturnType!overload)~" with method ", fullyQualifiedName!A, ".", name, "[#", i, "]");
                                } //todo else assert exactly one ignore and any Bind

                                static foreach (bind; getAnnotations!(overload, Bind)){
                                    log.info.emit("Binding type "~fullyQualifiedName!(Bind.As)~" with method ", fullyQualifiedName!A, ".", name, "[#", i, "]");
                                    internals.injector.bind!(Bind.As)(new ConfigurationMethodProvider!(A, name, i)(log.logSink));
                                    log.info.emit("Bound "~fullyQualifiedName!(Bind.As)~" with method ", fullyQualifiedName!A, ".", name, "[#", i, "]");
                                }
                            }
                        }
                    }
                }
                log.info.emit("Bound chosen members on configuration ", fullyQualifiedName!A);
            }
        }
    }


    void after(GluedInternals internals){}
    
    void onContextFreeze(GluedInternals internals){}
}
