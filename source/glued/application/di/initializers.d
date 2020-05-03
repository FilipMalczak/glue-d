module glued.application.di.initializers;

import std.meta;
import std.traits;

import glued.annotations;
import glued.logging;

import glued.application.di.annotations;

import dejector;

template queryForField(T, string name){ 
    alias annotation = getAnnotation!(__traits(getMember, T, name), Autowire); 
    static if (is(annotation.Query == DefaultQuery)){ 
        alias queryForField = typeof(__traits(getMember, T, name)); 
    } else { 
        alias queryForField = annotation.Query; 
    } 
} 


class InstanceInitializer(T, bool checkNulls): Initializer {
    mixin CreateLogger;
    private Dejector injector;
    private Logger log;

    this(Dejector injector){
        this.injector = injector;
        log = Logger(injector.get!(LogSink));
    }

    override void initialize(Object o){
        log.debug_.emit("Instance initialization for ", &o, " of type ", fullyQualifiedName!T);
        T t = (cast(T)o);
        log.debug_.emit("Field injection for ", &o, " of type ", fullyQualifiedName!T);
        fieldInjection(t);
        //        //split to field components/values injection
        //        methodInjection(t);
        //        postConstructInjection(t);
        log.debug_.emit("Instance initialization for ", &o, " of type ", fullyQualifiedName!T, " finished");
    }

    private void fieldInjection(T t){
        static foreach (i, name; FieldNameTuple!T){
            static if (__traits(getProtection, __traits(getMember, T, name)) == "public" && hasOneAnnotation!(__traits(getMember, T, name), Autowire)){
                mixin("import "~moduleName!(queryForField!(T, name))~";");
                static if (checkNulls) {
                    if (__traits(getMember, t, name) is null) {
                        log.debug_.emit("Injecting ", name, " with query ", fullyQualifiedName!(queryForField!(T, name)), " after null check");
                        __traits(getMember, t, name) = this.injector.get!(queryForField!(T, name));
                        log.debug_.emit("Injected ", name, " after null check");
                    } else {
                        log.debug_.emit(name, " didn't pass null check (value=", __traits(getMember, t, name), ")");
                    }
                } else {
                    log.debug_.emit("Injecting ", name, " with query ", fullyQualifiedName!(queryForField!(T, name)), " with no null check");
                    __traits(getMember, t, name) = this.injector.get!(queryForField!(T, name));
                    log.debug_.emit("Injected ", name, " with no null check");
                }
            } // else assert has no Autowire annotations
        }
    }
}

class ComponentSeedInitializer(T): InstanceInitializer!(T, false) {
    mixin CreateLogger;
    private Dejector injector;
    private Logger log;

    this(Dejector injector){
        super(injector);
        this.injector = injector;
        log = Logger(injector.get!(LogSink));
    }

    override void initialize(Object o){
        log.debug_.emit("Seed initialization for ", &o, " of type ", fullyQualifiedName!T);
        T t = (cast(T)o);
        log.debug_.emit("Constructor injection for ", &o, " of type ", fullyQualifiedName!T);
        constructorInjection(t);
        super.initialize(o);
        log.debug_.emit("Seed initialization for ", &o, " of type ", fullyQualifiedName!T, " finished");
    }

    private void constructorInjection(T t){
        static if (hasMember!(T, "__ctor")) {
            bool ctorCalled = false;
            static foreach (i, ctor; __traits(getOverloads, T.__ctor)){
                static if (__traits(getProtection, ctor) == "public" && hasOneAnnotation!(ctor, Constructor)){
                    //todo when only one constructor - default
                    assert(!ctorCalled); //todo static?
                    log.debug_.emit("Calling constructor for seed ", &t, " of type ", fullyQualifiedName!T);
                    resolveCall(this.injector, __traits(getOverloads, t, "__ctor")[i]);
                    //mixin(callCtor!(Parameters!(ctor)());
                    log.debug_.emit("Called constructor for instance", &t);
                    //todo maybe we can allow for many constructors?
                    ctorCalled = true;
                } // else assert not hasAnnotations
            }
        }
    }
}
