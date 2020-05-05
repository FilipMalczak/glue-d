module glued.application.di.initializers;

import std.algorithm;
import std.meta;
import std.traits;

import glued.annotations;
import glued.logging;

import glued.application.di.annotations;
import glued.application.di.resolveCall;

import dejector;

template queryForField(T, string name)
    if (is(T == class))
{ 
    alias annotation = getAnnotation!(__traits(getMember, T, name), Autowire); 
    static if (is(annotation.Query == DefaultQuery)){ 
        alias queryForField = typeof(__traits(getMember, T, name)); 
    } else { 
        alias queryForField = annotation.Query; 
    } 
} 

template queryForProperty(T, string name, size_t overloadIdx)
    if (is(T == class))
{ 
    alias annotation = getAnnotation!(__traits(getOverloads, T, name)[overloadIdx], Autowire); 
    static if (is(annotation.Query == DefaultQuery)){ 
        alias queryForProperty = Parameters!(__traits(getOverloads, T, name)[overloadIdx])[0]; 
    } else { 
        alias queryForProperty = annotation.Query; 
    } 
} 

class InstanceInitializer(T, bool checkNulls): Initializer 
    if (is(T == class))
{
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
        propertyInjection(t);
        //        //split to field components/values injection
        //        methodInjection(t);
        //        postConstructInjection(t);
        log.debug_.emit("Instance initialization for ", &o, " of type ", fullyQualifiedName!T, " finished");
    }

    private void fieldInjection(T t){
        enum isPublic(string name) = __traits(getProtection, __traits(getMember, T, name)) == "public";
        enum isAutowired(string name) = hasOneAnnotation!(__traits(getMember, T, name), Autowire);
        auto hasNullValue(string name)()
        {
            return __traits(getMember, t, name) is null;
        }
        static foreach (i, name; FieldNameTuple!T){
            static if (isPublic!name && isAutowired!name){
                mixin("import "~moduleName!(queryForField!(T, name))~";");
                static if (checkNulls) {
                    if (hasNullValue!name()) {
                        log.debug_.emit("Injecting field ", name, " with query ", fullyQualifiedName!(queryForField!(T, name)), " after null check");
                        __traits(getMember, t, name) = this.injector.get!(queryForField!(T, name));
                        log.debug_.emit("Injected field ", name, " after null check");
                    } else {
                        log.debug_.emit("Field ", name, " didn't pass null check (value=", __traits(getMember, t, name), ")");
                    }
                } else {
                    log.debug_.emit("Injecting field ", name, " with query ", fullyQualifiedName!(queryForField!(T, name)), " with no null check");
                    __traits(getMember, t, name) = this.injector.get!(queryForField!(T, name));
                    log.debug_.emit("Injected field ", name, " with no null check");
                }
            }
        }
    }
    
    private void propertyInjection(T t){
        enum isPublic(string name, size_t overloadIdx) = __traits(getProtection, __traits(getOverloads, T, name)[overloadIdx]) == "public";
        enum isAutowired(string name, size_t overloadIdx) = hasOneAnnotation!(__traits(getOverloads, T, name)[overloadIdx], Autowire);
        enum isMarkedAsProperty(string name, size_t overloadIdx) = hasFunctionAttributes!(__traits(getOverloads, T, name)[overloadIdx], "@property");
        enum isVoidMethod(string name, size_t overloadIdx) = is(ReturnType!(__traits(getOverloads, T, name)[overloadIdx]) == void);
        enum hasOneParam(string name, size_t overloadIdx) = Parameters!(__traits(getOverloads, T, name)[overloadIdx]).length == 1;
        static foreach (i, name; __traits(allMembers, T))
        {
            static foreach (j, _ignored; __traits(getOverloads, T, name))
            {
                static if (isPublic!(name, j) && 
                            isAutowired!(name, j) && 
                            isMarkedAsProperty!(name, j) &&
                            isVoidMethod!(name, j) &&
                            hasOneParam!(name, j))
                {
                    log.debug_.emit("Injecting property ", name, " with query ", fullyQualifiedName!(queryForProperty!(T, name, j)));
                     __traits(getOverloads, t, name)[j](injector.get!(queryForProperty!(T, name, j)));
                    log.debug_.emit("Injecting property ", name);
                }
            }
        }
    }
}

class ComponentSeedInitializer(T): InstanceInitializer!(T, false) 
    if (is(T == class))
{
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
        //todo refactor like superclass
        static if (hasMember!(T, "__ctor")) {
            bool ctorCalled = false;
            static foreach (i, ctor; __traits(getOverloads, T, "__ctor")){
                static if (__traits(getProtection, ctor) == "public" && hasOneAnnotation!(ctor, Constructor)){
                    //todo when only one constructor - default
                    assert(!ctorCalled); //todo static?
                    log.debug_.emit("Calling constructor for seed ", &t, " of type ", fullyQualifiedName!T);
                    resolveCall(this.injector, &__traits(getOverloads, t, "__ctor")[i]);
                    //mixin(callCtor!(Parameters!(ctor)());
                    log.debug_.emit("Called constructor for instance", &t);
                    //todo maybe we can allow for many constructors?
                    ctorCalled = true;
                } // else assert not hasAnnotations
            }
        }
    }
}
