module glued.application.di.initializers;

import std.algorithm;
import std.meta;
import std.traits;

import glued.annotations;
import glued.logging;

import glued.adhesives.environment;

import glued.application.di.annotations;
import glued.application.di.resolveCall;

import dejector;

private template queryForField(T, string name)
    if (is(T == class))
{ 
    alias annotation = getAnnotation!(__traits(getMember, T, name), Autowire); 
    static if (is(annotation.Query == DefaultQuery))
    { 
        alias queryForField = typeof(__traits(getMember, T, name)); 
    } 
    else 
    { 
        alias queryForField = annotation.Query; 
    } 
} 

private template queryForProperty(T, string name, size_t overloadIdx)
    if (is(T == class))
{ 
    alias annotation = getAnnotation!(__traits(getOverloads, T, name)[overloadIdx], Autowire); 
    static if (is(annotation.Query == DefaultQuery))
    { 
        alias queryForProperty = Parameters!(__traits(getOverloads, T, name)[overloadIdx])[0]; 
    } 
    else 
    { 
        alias queryForProperty = annotation.Query; 
    } 
} 

/**
 * Injects dependencies to existing instance.
 *
 * Finds every public field or property setter (single-param method with @property
 * attribute that returns void) that is annotated with Autowire.
 */
class InstanceInitializer(T, bool checkNulls): Initializer 
    if (is(T == class))
{
    mixin CreateLogger;
    private Dejector injector;
    private Environment environment;
    private Logger log;

    this(Dejector injector)
    {
        this.injector = injector;
        environment = injector.get!Environment;
        log = Logger(injector.get!(LogSink));
    }

    override void initialize(Object o)
    {
        log.debug_.emit("Instance initialization for ", &o, " of type ", fullyQualifiedName!T);
        T t = (cast(T)o);
        log.debug_.emit("Field injection for ", &o, " of type ", fullyQualifiedName!T);
        fieldInjection(t);
        propertyInjection(t);
        //postConstructInjection(t);
        log.debug_.emit("Instance initialization for ", &o, " of type ", fullyQualifiedName!T, " finished");
    }

    private void fieldInjection(T t)
    {
        enum isPublic(string name) = __traits(getProtection, __traits(getMember, T, name)) == "public";
        enum isAutowired(string name) = hasOneAnnotation!(__traits(getMember, T, name), Autowire);
        enum isValueInjected(string name) = hasOneAnnotation!(__traits(getMember, T, name), Value);
        enum isPrimitive(string name) = isScalarType!(typeof(__traits(getMember, T, name)));
        auto hasNullValue(string name)()
        {
            return __traits(getMember, t, name) is null;
        }
        
        static foreach (i, name; FieldNameTuple!T)
        {
            static if (isPublic!name)
            {
                static if (isAutowired!name)
                //todo check if interface/object field
                {
                    mixin("import "~moduleName!(queryForField!(T, name))~";");
                    static if (checkNulls) 
                    {
                        if (hasNullValue!name()) 
                        {
                            log.debug_.emit("Injecting field ", name, " with query ", fullyQualifiedName!(queryForField!(T, name)), " after null check");
                            __traits(getMember, t, name) = this.injector.get!(queryForField!(T, name));
                            log.debug_.emit("Injected field ", name, " after null check");
                        } 
                        else 
                        {
                            log.debug_.emit("Field ", name, " didn't pass null check (value=", __traits(getMember, t, name), ")");
                        }
                    } 
                    else 
                    {
                        log.debug_.emit("Injecting field ", name, " with query ", fullyQualifiedName!(queryForField!(T, name)), " with no null check");
                        __traits(getMember, t, name) = this.injector.get!(queryForField!(T, name));
                        log.debug_.emit("Injected field ", name, " with no null check");
                    }
                }
                static if (isValueInjected!name)
                {
//                    static if (isPrimitive!name)
//                    {
//                        import std.conv;
//                        string envval = environment.
//                    }
//                    else
                        static assert(false, "Support incoming!");
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

/**
 * Initializes freshly created instance (for which constructor wasn't called yet).
 * Besides standard injection methods performs constructor injection.
 * 
 * If aggregate has many constructors, up to one of them can be annotated
 * with Constructor - that one will be called.
 * If there is only one constructor it will be called by default. To turn this
 * behaviour off annotate that constructor with DontInject.
 */
class ComponentSeedInitializer(T): InstanceInitializer!(T, false) 
    if (is(T == class))
{
    mixin CreateLogger;
    private Dejector injector;
    private Logger log;

    this(Dejector injector)
    {
        super(injector);
        this.injector = injector;
        log = Logger(injector.get!(LogSink));
    }

    override void initialize(Object o)
    {
        log.debug_.emit("Seed initialization for ", &o, " of type ", fullyQualifiedName!T);
        T t = (cast(T)o);
        log.debug_.emit("Constructor injection for ", &o, " of type ", fullyQualifiedName!T);
        constructorInjection(t);
        super.initialize(o);
        log.debug_.emit("Seed initialization for ", &o, " of type ", fullyQualifiedName!T, " finished");
    }

    private void constructorInjection(T t)
    {
        enum isPublic(alias ctor) = __traits(getProtection, ctor) == "public";
        enum isAnnotatedForInjection(alias ctor) = hasOneAnnotation!(ctor, Constructor);
        enum isAnnotatedForIgnoring(alias ctor) = hasOneAnnotation!(ctor, DontInject);
        
        static if (hasMember!(T, "__ctor")) 
        {
            static if (__traits(getOverloads, T, "__ctor").length == 1 && 
                        isPublic!(__traits(getOverloads, T, "__ctor")[0]))
            {
                static if(isAnnotatedForIgnoring!(__traits(getOverloads, t, "__ctor")[0]))
                {
                    log.debug_.emit("Sole constructor for seed ", &t, " of type ", fullyQualifiedName!T, " is ignored");
                }
                else
                {
                    log.debug_.emit("Calling default constructor for seed ", &t, " of type ", fullyQualifiedName!T);
                    resolveCall(this.injector, &__traits(getOverloads, t, "__ctor")[0]);
                    log.debug_.emit("Called default constructor for instance", &t);
                }
            }
            else 
            {
                bool ctorCalled = false;
                static foreach (i, ctor; __traits(getOverloads, T, "__ctor"))
                {
                    static if (isPublic!ctor && isAnnotatedForInjection!ctor)
                    {
                        assert(!ctorCalled);
                        log.debug_.emit("Calling constructor for seed ", &t, " of type ", fullyQualifiedName!T);
                        resolveCall!(__traits(getOverloads, T, "__ctor")[i])(this.injector, &__traits(getOverloads, t, "__ctor")[i]);
                        log.debug_.emit("Called constructor for instance", &t);
                        ctorCalled = true;
                    }
                }
                if (!ctorCalled)
                    log.debug_.emit("Couldn't find any constructor for seed ", &t, " of type ", fullyQualifiedName!T);
            }
        }
        else
        {
            log.debug_.emit("Couldn't find any constructor for seed ", &t, " of type ", fullyQualifiedName!T);
        }
    }
}
