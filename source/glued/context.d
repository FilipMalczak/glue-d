//todo shared! you've removed it all, same with synchronized
module glued.context;

import std.variant;
import std.meta;
import std.traits;
import std.string: join;
import std.functional : toDelegate;

import glued.stereotypes;
import glued.singleton;
import glued.mirror;
import glued.scan;
import glued.utils;

import dejector;

extern (C) Object _d_newclass(const TypeInfo_Class ci);

struct StereotypeDefinition(S) if (is(S == struct)) {
    S stereotype;
    LocatedAggregate target;
}

//todo this is useful only for testing
class BackboneContext {
    private LocatedAggregate[] _tracked;
    private Variant[][LocatedAggregate] _stereotypes;
    
    void track(string m, string n)() {
        version(glued_debug) {
            pragma(msg, "Tracking ", m, "::", n);
        }
        alias aggr = import_!(m, n);
        static if (qualifiesForTracking!(aggr)()){
            version(glued_debug) {
                pragma(msg, "qualifies!");
            }
            auto a = aggregate!(m, n)();
            _tracked ~= a;
            
            void gatherStereotypes(S)(S s){
                _stereotypes[aggregate!(S)()] ~= Variant(StereotypeDefinition!S(s, a));
            }
            static foreach (alias s; getStereotypes!aggr) {
                gatherStereotypes(s);
            }
        }
    }
    
    @property
    public LocatedAggregate[] tracked(){
        return this._tracked;
    }
    
    @property
    public Variant[][LocatedAggregate] stereotypes(){
        return this._stereotypes;
    }
    
    static bool qualifiesForTracking(alias T)(){
        return hasAnnotation!(T, Tracked);
    }
}

string generateImports(P...)(){
    string result;
    static foreach (p; P){
        result ~= "import "~moduleName!p~";\n";
    }
    return result;
}


string generateResolvedExpression(P...)(){
    //todo extension point when we introduce environment (key/val config)
    string result = "toCall(";
    string[] params;
    static foreach (p; P){
        result ~= "injector.get!("~fullyQualifiedName!p~")";
    }
    result ~= params.join(", ");
    result ~= ")";
    return result;
}

//todo reusable and useful
auto resolveCall(R, P...)(Dejector injector, R function(P) toCall){
    return resolveCall(injector, toDelegate(foo));
}

auto resolveCall(R, P...)(Dejector injector, R delegate(P) toCall){
    mixin(generateImports!(P)());
    static if (is(ReturnType!foo == void)){
        version(debug_glued_context) {
            pragma(msg, "@", __FILE__, ":", __LINE__, "mixing in:");
            pragma(msg, generateResolvedExpression!(P)()~";");
        }
        mixin(generateResolvedExpression!(P)()~";");
    } else {
        version(debug_glued_context) {
            pragma(msg, "@", __FILE__, ":", __LINE__, "mixing in:");
            pragma(msg, "return "~generateResolvedExpression!(P)()~";");
        }
        mixin("return "~generateResolvedExpression!(P)()~";");
    }
}

//template resolveCall(alias injector, alias foo){
//    alias params = Parameters!foo;
//    //todo extension point when we introduce environment (key/val config)
//    alias resolved = staticMap!(injector.get, params);
//    enum resolveCall = foo(resolved);
//}

void log(string f=__FILE__, int l=__LINE__, T...)(T args){
    version(debug_glued_context_runtime){
        import std.stdio;
        import std.range;
        import std.conv;
        writeln("@", f, ":", l, " | ", args);
    }
}

struct GluedCoreProcessor {
    static void before(){}
    
    static bool canHandle(A)(){
        return is(A == class) && (isMarkedAsStereotype!(A, Component) || isMarkedAsStereotype!(A, Configuration) );
    }
    
    static void handle(A)(GluedInternals internals){
        static if (isMarkedAsStereotype!(A, Component)) {
            import std.stdio;
            import std.traits;
            log("Binding ", fullyQualifiedName!A);
            internals.injector.bind!(A)(new ComponentClassProvider!A(internals.injector));
            log("Bound ", fullyQualifiedName!A, " based on its class definition");
        }
        static if (isMarkedAsStereotype!(A, Configuration)){
            import std.stdio;
            import std.traits;
            log("Binding based on configuration ", fullyQualifiedName!A);
            internals.injector.bind!(A, Singleton)(new ComponentClassProvider!A(internals.injector));
            A a;
            static foreach (name; __traits(allMembers, A)){
                static if (__traits(getProtection, __traits(getMember, A, name)) == "public" &&
                    isFunction!(__traits(getMember, A, name))) {
                        static foreach (i, overload; __traits(getOverloads, A, name)) {
                            static if (hasAnnotation!(overload, Component)) {
                                static if (!hasAnnotation!(overload, IgnoreResultBinding)){
                                    //todo reuse the same provider for many bindings
                                    log("Binding type "~fullyQualifiedName!(ReturnType!overload)~" with method ", fullyQualifiedName!A, ".", name, "[#", i, "]");
                                    internals.injector.bind!(ReturnType!overload)(new ConfigurationMethodProvider!(A, name, i)(internals.injector));
                                    log("Bound "~fullyQualifiedName!(ReturnType!overload)~" with method ", fullyQualifiedName!A, ".", name, "[#", i, "]");
                                } //todo else assert exactly one ignore and any Bind
                                
                                static foreach (bind; getAnnotations!(overload, Bind)){
                                    log("Binding type "~fullyQualifiedName!(Bind.As)~" with method ", fullyQualifiedName!A, ".", name, "[#", i, "]");
                                    internals.injector.bind!(Bind.As)(new ConfigurationMethodProvider!(A, name, i)(internals.injector));
                                    log("Bound "~fullyQualifiedName!(Bind.As)~" with method ", fullyQualifiedName!A, ".", name, "[#", i, "]");
                                }
                            }
                        }
                }
            }
            log("Bound chosen members on configuration ", fullyQualifiedName!A);
        }
    }

    
    static void after(){}
}

//todo good start, but lets keep it simple
//struct Qualifier(T...) if (allSatisfy!(isInterface, T)) {
//    alias qualifiers = T;
//}

struct Bind(T) {
    alias As = T;
}

struct IgnoreResultBinding {}

/**
 * "existing instance that should be autowired further". If you put this on configuration method, returned
 * instance will be considered "seed" 
 */
struct Seed {}

struct Constructor {}

struct PostConstruct {}

//todo predestruct


enum DefaultQuery;
struct Autowire(T=DefaultQuery) {
    alias Query = T;
}

template queryForField(T, string name){
    alias annotation = getAnnotation!(__traits(getMember, T, name), Autowire);
    static if (is(annotation.Query == DefaultQuery)){
        alias queryForField = typeof(__traits(getMember, T, name));
    } else {
        alias queryForField = annotation.Query;
    }
}

class InstanceInitializer(T, bool checkNulls): Initializer {
    private Dejector injector;
    
    this(Dejector injector){
        this.injector = injector;
    }

    override void initialize(Object o){
        traceWiring("Instance initialization for ", &o, " of type ", fullyQualifiedName!T);
        T t = (cast(T)o);
        traceWiring("Field injection for ", &o, " of type ", fullyQualifiedName!T);
        fieldInjection(t);
//        //split to field components/values injection
//        methodInjection(t);
//        postConstructInjection(t);
        traceWiring("Instance initialization for ", &o, " of type ", fullyQualifiedName!T, " finished");
    }
    
    private void fieldInjection(T t){
        static foreach (i, name; FieldNameTuple!T){
            static if (__traits(getProtection, __traits(getMember, T, name)) == "public" && hasOneAnnotation!(__traits(getMember, T, name), Autowire)){
                mixin("import "~moduleName!(queryForField!(T, name))~";");
                static if (checkNulls) {
                    if (__traits(getMember, t, name) is null) {
                        traceWiring("Injecting ", name, " with query ", fullyQualifiedName!(queryForField!(T, name)), " after null check");
                        __traits(getMember, t, name) = this.injector.get!(queryForField!(T, name));
                        traceWiring("Injected ", name, " after null check");
                    } else {
                        traceWiring(name, " didn't pass null check (value=", __traits(getMember, t, name), ")");
                    }
                } else {
                    traceWiring("Injecting ", name, " with query ", fullyQualifiedName!(queryForField!(T, name)), " with no null check");
                    __traits(getMember, t, name) = this.injector.get!(queryForField!(T, name));
                    traceWiring("Injected ", name, " with no null check");
                }
            } // else assert has no Autowire annotations
        }
    }
}

class ComponentSeedInitializer(T): InstanceInitializer!(T, false) {
    private Dejector injector;
    this(Dejector injector){
        super(injector);
        this.injector = injector;
    }

    override void initialize(Object o){
        traceWiring("Seed initialization for ", &o, " of type ", fullyQualifiedName!T);
        T t = (cast(T)o);
        traceWiring("Constructor injection for ", &o, " of type ", fullyQualifiedName!T);
        constructorInjection(t);
        super.initialize(o);
        traceWiring("Seed initialization for ", &o, " of type ", fullyQualifiedName!T, " finished");
    }
    
    private void constructorInjection(T t){
        static if (hasMember!(T, "__ctor")) {
            bool ctorCalled = false;
            static foreach (i, ctor; __traits(getOverloads, T.__ctor)){
                static if (__traits(getProtection, ctor) == "public" && hasOneAnnotation!(ctor, Constructor)){
                    //todo when only one constructor - default
                    assert(!ctorCalled); //todo static?
                    traceWiring("Calling constructor for seed ", &t, " of type ", fullyQualifiedName!T);
                    resolveCall(this.injector, __traits(getOverloads, t, "__ctor")[i]);
                    //mixin(callCtor!(Parameters!(ctor)());
                    traceWiring("Called constructor for instance", &t);
                    //todo maybe we can allow for many constructors?
                    ctorCalled = true;
                } // else assert not hasAnnotations 
            }
        }
    }
}

//todo is(class)
class ComponentClassProvider(T): Provider {
    private Dejector injector;
    this(Dejector injector){
        this.injector = injector;
    }
    
    override Initialization get(){
        traceWiring("Building seed of type ", fullyQualifiedName!T);
        auto seed = cast(T) _d_newclass(T.classinfo);
        traceWiring("Built seed ", &seed, " of type ", fullyQualifiedName!T);
        return new Initialization(seed, false, new ComponentSeedInitializer!T(injector));
    }
}

class ConfigurationMethodProvider(C, string name, size_t i): Provider {
    private Dejector injector;
    this(Dejector injector){
        this.injector = injector;
    }
    
    override Initialization get(){
        traceWiring("Resolving configuration class instance ", fullyQualifiedName!C);
        C config = injector.get!C;
        traceWiring("Resolved configuration class ", fullyQualifiedName!C, " instance ", &config);
        traceWiring("Building configuration method ", fullyQualifiedName!C, ".", name);
//        ReturnType!(__traits(getOverloads, config, name)[i]) foo(){
//            template step(int i, acc...){
//                static if (acc.length == Parameters!(__traits(getOverloads, config, name)[i]).length){
//                    alias step = acc;
//                } else {
//                    alias step = step!(i+1, AliasSeq!(acc, injector.get!(Parameters!(__traits(getOverloads, config, name)[i])[i])));
//                }
//            }
//            return __traits(getOverloads, config, name)[i](step!0);
//        }
        auto instance = resolveCall(injector, &(__traits(getOverloads, config, name)[i]));
        enum isSeed = hasOneAnnotation!(__traits(getOverloads, C, name)[i], Seed); //todo assert not has many
        traceWiring("Built initialized instance ", &instance, " method ", fullyQualifiedName!C, ".", name);
        auto initializer = isSeed ? new InstanceInitializer!(C, true)(injector) : new NullInitializer;
        return new Initialization(cast(Object) instance, !isSeed, cast(Initializer) initializer);
    }
}

struct GluedInternals {
    Dejector injector;
}

class GluedContext(Processors...) {
    private GluedInternals internals;
    
    alias processors = AliasSeq!(Processors);
    
    this(){
        internals = GluedInternals(new Dejector());
        internals.injector.bind!(Dejector)(new InstanceProvider(internals.injector));
    }
    
    private void before(){
        static foreach (p; processors)
            p.before();
    }
    
    private void after(){
        static foreach (p; processors)
            p.after();
    }
    
    void scan(alias scannables)(){
        enum scanConsumer(string m, string n) = "track!(\""~m~"\", \""~n~"\")();";
        mixin unrollLoopThrough!(scannables, "void doScan() { ", scanConsumer, "}");
        
        before();
        doScan();
        after();
    }
    
    @property
    Dejector injector(){
        return internals.injector;
    }
    
    void track(string m, string n)(){
        version(debug_glued_context) {
            pragma(msg, "Tracking ", m, "::", n, " by ", typeof(this));
        }
        alias aggr = import_!(m, n);
        static if (qualifiesForTracking!(aggr)()){
            version(debug_glued_context) {
                pragma(msg, m, "::", n, " qualified for tracking by ", typeof(this));
            }
            static foreach (p; processors){
                static if (p.canHandle!(aggr)()){
                    version(debug_glued_context) {
                        pragma(msg, "Processor", p, " can handle ", m, "::", n, " when used with ", typeof(this));
                    }
                    p.handle!(aggr)(internals);
                }
            }
        }
    }
    
    
    private static bool qualifiesForTracking(alias T)(){
        return hasAnnotation!(T, Tracked);
    }
    
}

alias DefaultGluedContext = GluedContext!(GluedCoreProcessor);
