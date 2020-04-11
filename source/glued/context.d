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
import glued.logging;

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
    mixin CreateLogger;

    mixin(generateImports!(P)());
    static if (is(ReturnType!foo == void)){
        mixin(Logger.logged!(generateResolvedExpression!(P)()~";"));
    } else {
        mixin(Logger.logged.value!("return "~generateResolvedExpression!(P)()~";"));
    }
}

struct GluedCoreProcessor {
    mixin CreateLogger;
    Logger log;

    void before(){}
    
    static bool canHandle(A)(){
        return is(A == class) && (isMarkedAsStereotype!(A, Component) || isMarkedAsStereotype!(A, Configuration) );
    }
    
    void handle(A)(GluedInternals internals){
        static if (isMarkedAsStereotype!(A, Component)) {
            import std.stdio;
            import std.traits;
            log.info.emit("Binding ", fullyQualifiedName!A);
            internals.injector.bind!(A)(new ComponentClassProvider!A(internals.injector));
            log.info.emit("Bound ", fullyQualifiedName!A, " based on its class definition");
        }
        static if (isMarkedAsStereotype!(A, Configuration)){
            import std.stdio;
            import std.traits;
            log.info.emit("Binding based on configuration ", fullyQualifiedName!A);
            internals.injector.bind!(A, Singleton)(new ComponentClassProvider!A(internals.injector));
            A a;
            static foreach (name; __traits(allMembers, A)){
                static if (__traits(getProtection, __traits(getMember, A, name)) == "public" &&
                    isFunction!(__traits(getMember, A, name))) {
                        static foreach (i, overload; __traits(getOverloads, A, name)) {
                            static if (hasAnnotation!(overload, Component)) {
                                static if (!hasAnnotation!(overload, IgnoreResultBinding)){
                                    //todo reuse the same provider for many bindings
                                    log.info.emit("Binding type "~fullyQualifiedName!(ReturnType!overload)~" with method ", fullyQualifiedName!A, ".", name, "[#", i, "]");
                                    internals.injector.bind!(ReturnType!overload)(new ConfigurationMethodProvider!(A, name, i)(internals.injector));
                                    log.info.emit("Bound "~fullyQualifiedName!(ReturnType!overload)~" with method ", fullyQualifiedName!A, ".", name, "[#", i, "]");
                                } //todo else assert exactly one ignore and any Bind
                                
                                static foreach (bind; getAnnotations!(overload, Bind)){
                                    log.info.emit("Binding type "~fullyQualifiedName!(Bind.As)~" with method ", fullyQualifiedName!A, ".", name, "[#", i, "]");
                                    internals.injector.bind!(Bind.As)(new ConfigurationMethodProvider!(A, name, i)(internals.injector));
                                    log.info.emit("Bound "~fullyQualifiedName!(Bind.As)~" with method ", fullyQualifiedName!A, ".", name, "[#", i, "]");
                                }
                            }
                        }
                }
            }
            log.info.emit("Bound chosen members on configuration ", fullyQualifiedName!A);
        }
    }

    
    void after(){}
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

//todo is(class)
class ComponentClassProvider(T): Provider {
    mixin CreateLogger;
    private Dejector injector;
    private Logger log;
    
    this(Dejector injector){
        this.injector = injector;
        log = Logger(injector.get!(LogSink));
    }
    
    override Initialization get(){
        log.debug_.emit("Building seed of type ", fullyQualifiedName!T);
        auto seed = cast(T) _d_newclass(T.classinfo);
        log.debug_.emit("Built seed ", &seed, " of type ", fullyQualifiedName!T);
        return new Initialization(seed, false, new ComponentSeedInitializer!T(injector));
    }
}

class ConfigurationMethodProvider(C, string name, size_t i): Provider {
    mixin CreateLogger;
    private Dejector injector;
    private Logger log;
    
    this(Dejector injector){
        this.injector = injector;
        log = Logger(injector.get!(LogSink));
    }
    
    override Initialization get(){
        log.debug_.emit("Resolving configuration class instance ", fullyQualifiedName!C);
        C config = injector.get!C;
        log.debug_.emit("Resolved configuration class ", fullyQualifiedName!C, " instance ", &config);
        log.debug_.emit("Building configuration method ", fullyQualifiedName!C, ".", name);
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
        log.debug_.emit("Built initialized instance ", &instance, " method ", fullyQualifiedName!C, ".", name);
        auto initializer = isSeed ? new InstanceInitializer!(C, true)(injector) : new NullInitializer;
        return new Initialization(cast(Object) instance, !isSeed, cast(Initializer) initializer);
    }
}

struct GluedInternals {
    Dejector injector;
}

class GluedContext(Processors...) {
    private LogSink logSink;
    private GluedInternals internals;
    mixin CreateLogger;
    private Logger log;
    
    alias processors = AliasSeq!(Processors);
    
    this(LogSink logSink){
        this.logSink = logSink;
        this.log = Logger(logSink);
        internals = GluedInternals(new Dejector());
        internals.injector.bind!(Dejector)(new InstanceProvider(internals.injector));
        internals.injector.bind!(LogSink)(new InstanceProvider(cast(Object) logSink));
    }
    
    private void before(){
        static foreach (P; processors)
            P(P.Logger(logSink)).before();
    }
    
    private void after(){
        static foreach (P; processors)
            P(P.Logger(logSink)).after();
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
        log.Info.Emit!("Tracking ", m, "::", n);
        alias aggr = import_!(m, n);
        static if (qualifiesForTracking!(aggr)()){
            log.Info.Emit!(m, "::", n, " qualified for tracking by ", typeof(this));
            static foreach (P; processors){
                static if (P.canHandle!(aggr)()){
                    log.Info.Emit!("Processor", P, " can handle ", m, "::", n, " when used with ", typeof(this));
                    P(P.Logger(logSink)).handle!(aggr)(internals);
                }
            }
        }
    }
    
    
    private static bool qualifiesForTracking(alias T)(){
        return hasAnnotation!(T, Tracked);
    }
    
}

alias DefaultGluedContext = GluedContext!(GluedCoreProcessor);
