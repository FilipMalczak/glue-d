//todo shared! you've removed it all, same with synchronized
module glued.context;

import std.variant;
import std.meta;
import std.array;
import std.algorithm;
import std.traits;
import std.string: join;
import std.functional : toDelegate;

import glued.stereotypes;
import glued.singleton;
import glued.mirror;
import glued.scan;
import glued.utils;
import glued.logging;
import glued.collections;

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

struct ConcreteTypesProcessor {
    mixin CreateLogger;
    Logger log;

    void before(GluedInternals internals){}
    
    static bool canHandle(A)(){
        return is(A == class) && (isMarkedAsStereotype!(A, Component) || isMarkedAsStereotype!(A, Configuration) );
    }
    
    void handle(A)(GluedInternals internals){
        static if (isMarkedAsStereotype!(A, Component)) {
            import std.stdio;
            import std.traits;
            log.info.emit("Binding ", fullyQualifiedName!A);
            internals.injector.bind!(A)(new ComponentClassProvider!A(log.logSink));
            log.info.emit("Bound ", fullyQualifiedName!A, " based on its class definition");
        }
        static if (isMarkedAsStereotype!(A, Configuration)){
            import std.stdio;
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

    
    void after(GluedInternals internals){}
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
    private Logger log;
    
    this(LogSink logSink){
        log = Logger(logSink);
    }
    
    override Initialization get(Dejector injector){
        log.debug_.emit("Building seed of type ", fullyQualifiedName!T);
        auto seed = cast(T) _d_newclass(T.classinfo);
        log.debug_.emit("Built seed ", &seed, " of type ", fullyQualifiedName!T);
        return new Initialization(seed, false, new ComponentSeedInitializer!T(injector));
    }
}

class ConfigurationMethodProvider(C, string name, size_t i): Provider {
    mixin CreateLogger;
    private Logger log;
    
    this(LogSink logSink){
        log = Logger(logSink);
    }
    
    override Initialization get(Dejector injector){
        log.debug_.emit("Resolving configuration class instance ", fullyQualifiedName!C);
        C config = injector.get!C;
        log.debug_.emit("Resolved configuration class ", fullyQualifiedName!C, " instance ", &config);
        log.debug_.emit("Building configuration method ", fullyQualifiedName!C, ".", name);
        auto instance = resolveCall(injector, &(__traits(getOverloads, config, name)[i]));
        enum isSeed = hasOneAnnotation!(__traits(getOverloads, C, name)[i], Seed); //todo assert not has many
        log.debug_.emit("Built initialized instance ", &instance, " method ", fullyQualifiedName!C, ".", name);
        auto initializer = isSeed ? new InstanceInitializer!(C, true)(injector) : new NullInitializer;
        return new Initialization(cast(Object) instance, !isSeed, cast(Initializer) initializer);
    }
}

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

struct GluedInternals {
    Dejector injector;
    LogSink logSink;
    InheritanceIndex inheritanceIndex;
}

class GluedContext(Processors...) {
    private GluedInternals internals;
    mixin CreateLogger;
    private Logger log;
    
    alias processors = AliasSeq!(Processors);
    
    @property //fixme should it be private?
    private LogSink logSink(){
        return internals.logSink;
    }
    
    this(LogSink logSink){
        this.log = Logger(logSink);
        internals = GluedInternals(new Dejector(), logSink, new InheritanceIndex(logSink));
        internals.injector.bind!(Dejector)(new InstanceProvider(internals.injector));
        internals.injector.bind!(LogSink)(new InstanceProvider(cast(Object) logSink));
    }
    
    private void before(){
        static foreach (P; processors)
            P(P.Logger(logSink)).before(internals);
    }
    
    private void after(){
        static foreach (P; processors)
            P(P.Logger(logSink)).after(internals);
    }
    
    void scan(alias scannables)(){
        enum scanConsumer(string m, string n) = "track!(\""~m~"\", \""~n~"\")();";
        mixin unrollLoopThrough!(scannables, "void doScan() { ", scanConsumer, "}");
        
        log.info.emit("Before ", scannables);
        before();
        log.info.emit("Scanning ", scannables);
        doScan();
        log.info.emit("After ", scannables);
        after();
        log.info.emit("Scan of ", scannables, " finished");
    }
    
    @property
    Dejector injector(){
        return internals.injector;
    }
    
    @property
    InheritanceIndex inheritanceIndex(){
        return internals.inheritanceIndex;
    }
    
    void track(string m, string n)(){
        log.info.emit("Tracking ", m, "::", n);
        alias aggr = import_!(m, n);
        static if (qualifiesForTracking!(aggr)()){
            log.info.emit(m, "::", n, " qualifies for tracking");
            static foreach (P; processors){
                static if (P.canHandle!(aggr)()){
                    log.info.emit("Processor", fullyQualifiedName!P, " can handle ", m, "::", n);
                    P(P.Logger(logSink)).handle!(aggr)(internals); //todo pass sink only, let P create Logger
                }
            }
        }
    }
    
    
    private static bool qualifiesForTracking(alias T)(){
        return hasAnnotation!(T, Tracked);
    }
    
}

alias DefaultGluedContext = GluedContext!(ConcreteTypesProcessor, InterfaceProcessor);
