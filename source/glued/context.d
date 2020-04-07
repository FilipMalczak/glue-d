module glued.context;

import std.variant;
import std.meta;
import std.traits;
import std.array;
import std.conv;
import std.range;
import std.algorithm;

import poodinis;

import glued.stereotypes;
import glued.singleton;
import glued.mirror;
import glued.scan;
import glued.utils;

struct StereotypeDefinition(S) if (is(S == struct)) {
    S stereotype;
    LocatedAggregate target;
}

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

//todo reusable and useful
template resolveCall(alias context, alias foo){
    alias params = Parameters!foo;
    alias resolved = staticMap!(context.resolve, params);
    alias resolveCall = foo(resolved);
}

//todo support for these
//struct RegisterAs!T {
//    T dummy;
//}

//struct Prototype {}

/**
 * "Interface"" of each processing step; not real D, but describes how to
 * create a new processor.
 */
//struct Processor {
//    static struct State {}
//
//    static State init(GluedInternals);
//    static bool canHadle(A)(State state);
//    static State handle(A)(State state);
//    static void after(State);
//}

//struct GluedDiProcessor {
//    alias provider = object delegate();
//    struct ProviderEntry { string id; provider foo; }

//    static struct State {
//        shared DependencyContainer container;
//        string[string] dependencies;
//        ProviderEntry[] byComponent;
//        ProviderEntry[] byConfig;
//    }

//    static State before(GluedInternals internals){
//        return State(internals.diContext);
//    }
//    
//    static bool canHandle(A)(State state){
//        return is(A == class) && (isMarkedAsStereotype!(A, Component) || isMarkedAsStereotype!(A, Configuration));
//    }
//    
//    static State handle(A)(State state){
//        static if (isMarkedAsStereotype!(A, Component)) {
//            import std.stdio;
//            import std.traits;
//            writeln("registering ", fullyQualifiedName!A);
//            state.container.register!A;
//        }
//        static if (isMarkedAsStereotype!(A, Configuration)){
//            import poodinis;
//            state.container.registerContext!A;
//        }
//        return state;
//    }
//    
//    static void after(State state){}
//}

//struct SimpleDiProcessor {
//    static struct State {
//        shared DependencyContainer container;
//    }

//    static State before(GluedInternals internals){
//        return State(internals.diContext);
//    }
//    
//    static bool canHandle(A)(State state){
//        return is(A == class) && (isMarkedAsStereotype!(A, Register) || (isMarkedAsStereotype!(A, Configuration) && is(A: ApplicationContext)));
//    }
//    
//    static State handle(A)(State state){
//        static if (isMarkedAsStereotype!(A, Register)) {
//            import std.stdio;
//            import std.traits;
//            writeln("registering ", fullyQualifiedName!A);
//            state.container.register!A;
//        }
//        static if (isMarkedAsStereotype!(A, Configuration)){
//            import poodinis;
//            state.container.registerContext!A;
//        }
//        return state;
//    }

//    
//    static void after(State state){}
//}

struct SimpleDiProcessor {
    static void before(){}
    
    static bool canHandle(A)(){
        return is(A == class) && (isMarkedAsStereotype!(A, Register) || (isMarkedAsStereotype!(A, Configuration) && is(A: ApplicationContext)));
    }
    
    static void handle(A)(GluedInternals internals){
        static if (isMarkedAsStereotype!(A, Register)) {
            import std.stdio;
            import std.traits;
            writeln("registering ", fullyQualifiedName!A);
            internals.diContext.register!A;
        }
        static if (isMarkedAsStereotype!(A, Configuration)){
            import poodinis;
            import std.stdio;
            import std.traits;
            writeln("registering based on configuration ", fullyQualifiedName!A);
            internals.diContext.registerContext!A;
        }
    }

    
    static void after(){}
}

//template ConfigWrapper(A) {
//    import std.conv: to;

//    string delegateMethods(){
//        string result;
//        string imports(string member)(){
//            string[] result;
//            static foreach (p; Parameters!(__traits(getMember, A, member))){
//                result ~= moduleName!p;
//            }
//            return result.uniq.map!((s) => "import "~s~";\n").join("");
//        }
//        enum param(T) = "to!("~fullyQualifiedName!T~")(container.resolve!("~fullyQualifiedName!T~"))";
//        string params(string member)(){
//            string[] result;
//            static foreach (p; Parameters!(__traits(getMember, A, member))){
//                result ~= param!p;
//            }
//            return result.join(", ");
//        }
//        string[] classImports;
//        static foreach (member; __traits(allMembers, A)){
//            static if (__traits(getProtection, __traits(getMember, A, member)) == "public" && hasAnnotation!(__traits(getMember, A, member), Component)) { 
//                classImports ~= moduleName!(ReturnType!(__traits(getMember, A, member)));
//            }
//        }
//        result ~= classImports.uniq.map!((s) => "import "~s~";\n").join("");
//        static foreach (member; __traits(allMembers, A)){
//            static if (__traits(getProtection, __traits(getMember, A, member)) == "public" && hasAnnotation!(__traits(getMember, A, member), Component)) { 
//                result ~= "@Component ";
//                foreach(attribute; __traits(getAttributes, __traits(getMember, A, member))) {
//                    static if (is(attribute == RegisterByType!T, T)) {
//                        result ~= "@RegisterByType!("~fullyQualifiedName!T~") "; //todo this will fail if T is in another module
//                    } else static if (__traits(isSame, attribute, Prototype)) {
//                        result ~= "@Prototype ";
//                    }
//                }
//                result ~= fullyQualifiedName!(ReturnType!(__traits(getMember, A, member)))~" "~member~"(){\n";
//                result ~= imports!(member)();
//                result ~= "return gluedConfig."~member~"(";
//                result ~= params!(member)();
//                result ~= ");\n}\n";
//            }
//        }
//        return result;
//    }
//    
//    class ConfigWrapper: ApplicationContext {
//        import poodinis: Autowire, Component, RegisterByType, Prototype;
//        @Autowire
//        A gluedConfig;
//        
//        shared DependencyContainer container;
//        
//        pragma(msg, "wrapper: "~delegateMethods());
//        mixin(delegateMethods());
//    }
//}

//struct GluedConfigurationProcessor {

//    static void before(){}
//    
//    static void after(){}
//    
//    static bool canHandle(A)(){
//        pragma(msg, "XXX ", A, "  ", is(A == class) , isMarkedAsStereotype!(A, Configuration) , !is(A: ApplicationContext));
//        return is(A == class) && isMarkedAsStereotype!(A, Configuration) && !is(A: ApplicationContext);
//    }
//    
//    static void handle(A)(GluedInternals internals){
//        import std.stdio;
//        writeln("registering ", fullyQualifiedName!A);
//        internals.diContext.register!A;
//        writeln("registering based on configuration ", fullyQualifiedName!(ConfigWrapper!A), " (derived from ", fullyQualifiedName!A, ")");
//        internals.diContext.registerContext!(ConfigWrapper!A);
//        ConfigWrapper!A wrapper = internals.diContext.resolve!(ConfigWrapper!A);
//        wrapper.container = internals.diContext;
//    }

template ConfigWrapper(A, string member, size_t i) {
    import std.conv: to;

    string delegateMethods(){
        string result;
        string imports(){
            string[] result;
            static foreach (p; Parameters!(__traits(getOverloads, A, member)[i])){
                result ~= moduleName!p;
            }
            return result.uniq.map!((s) => "import "~s~";\n").join("");
        }
        enum param(T) = "container.resolve!("~fullyQualifiedName!T~")";
        string params(){
            string[] result;
            static foreach (p; Parameters!(__traits(getOverloads, A, member)[i])){
                result ~= param!p;
            }
            return result.join(", ");
        }
        result ~= "import "~moduleName!(ReturnType!(__traits(getOverloads, A, member)[i]))~";\n";
        result ~= "@Component ";
        foreach(attribute; __traits(getAttributes, __traits(getOverloads, A, member)[i])) {
            static if (is(attribute == RegisterByType!T, T)) {
                result ~= "@RegisterByType!("~fullyQualifiedName!T~") "; //todo this will fail if T is in another module
            } else static if (__traits(isSame, attribute, Prototype)) {
                result ~= "@Prototype ";
            }
        }
        result ~= fullyQualifiedName!(ReturnType!(__traits(getOverloads, A, member)[i]))~" "~member~"(){\n";
        result ~= imports();
        result ~= "return gluedConfig."~member~"(";
        result ~= params();
        result ~= ");\n}\n";
        return result;
    }
    
    class ConfigWrapper: ApplicationContext {
        import poodinis: Autowire, Component, RegisterByType, Prototype;
        @Autowire
        A gluedConfig;
        
        shared DependencyContainer container;
        
        pragma(msg, "wrapper: "~delegateMethods());
        mixin(delegateMethods());
    }
}

struct GluedConfigurationProcessor {

    static void before(){}
    
    static void after(){}
    
    static bool canHandle(A)(){
        pragma(msg, "XXX ", A, "  ", is(A == class) , isMarkedAsStereotype!(A, Configuration) , !is(A: ApplicationContext));
        return is(A == class) && isMarkedAsStereotype!(A, Configuration) && !is(A: ApplicationContext);
    }
    
    static void handle(A)(GluedInternals internals){
        import std.stdio;
        writeln("registering ", fullyQualifiedName!A);
        internals.diContext.register!A;
        static foreach (member; __traits(allMembers, A)){
            static if (__traits(getProtection, __traits(getMember, A, member)) == "public" && 
                    hasAnnotation!(__traits(getMember, A, member), Component) &&
                    isCallable!(__traits(getMember, A, member))) { 
                static foreach (i; __traits(getOverloads, A, member).length.iota){
                    writeln("registering based on configuration ", fullyQualifiedName!(ConfigWrapper!(A, member, i)), " (derived from ", fullyQualifiedName!A, ")");
                    internals.diContext.registerContext!(ConfigWrapper!(A, member, i));
                    ConfigWrapper!(A, member, i) wrapper = internals.diContext.resolve!(ConfigWrapper!(A, member, i));
                    wrapper.container = internals.diContext;
               }
            }
        }

    }

//    static void handle(A)(GluedInternals internals){
//        //cant deny that this is a modified copy-paste from poodinis.context
//        auto container = internals.diContext;
//        container.register!A;
//        Object actualFactory(string member)(){
//            return resolveCall!(internals.diContext, &__traits(getMember, container.resolve!A, member));
//        }
//        static foreach (member ; __traits(allMembers, A)) {
//            pragma(msg, "handling ", A, ".", member);
//            //todo for now we use Component in configs and Register in classes to be picked up; sanitize it
//            static if (__traits(getProtection, __traits(getMember, A, member)) == "public" && hasAnnotation!(__traits(getMember, A, member), PoodinisComponent)) { 
//                auto factoryMethod = &__traits(getMember, A, member);
//                Registration registration = null;
//                auto createsSingleton = CreatesSingleton.yes;

//                foreach(attribute; __traits(getAttributes, __traits(getMember, A, member))) {
//                    static if (is(attribute == RegisterByType!T, T)) {
//                        registration = container.register!(typeof(attribute.type), ReturnType!factoryMethod);
//                    } else static if (__traits(isSame, attribute, Prototype)) {
//                        createsSingleton = CreatesSingleton.no;
//                    }
//                }

//                if (registration is null) {
//                    registration = container.register!(ReturnType!factoryMethod);
//                }
//                
////                ReturnType!factoryMethod actualFactory(){
////                    A a = container.resolve!A;
//////                    mixin("return resolveCall!(internals.diContext, a."~member~");");
////                    return resolveCall!(internals.diContext, &__traits(getMember, a, member));
////                }

//                registration.instanceFactory.factoryParameters = InstanceFactoryParameters(registration.instanceType, createsSingleton, null, &(actualFactory!member));
//            }
//        }
//    }
}

struct GluedInternals {
    shared DependencyContainer diContext;
}

synchronized class GluedContext {
    private GluedInternals internals;
    
    alias processors = AliasSeq!(SimpleDiProcessor, GluedConfigurationProcessor);
    
    this(){
        internals = GluedInternals(new shared DependencyContainer());
        internals.diContext.register!(DependencyContainer).existingInstance(cast(DependencyContainer) internals.diContext);
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
    shared(DependencyContainer) internalDiContext(){
        return internals.diContext;
    }
    
    void track(string m, string n)(){
        version(glued_debug) {
            pragma(msg, "Tracking ", m, "::", n, " by ", typeof(this));
        }
        alias aggr = import_!(m, n);
        static if (qualifiesForTracking!(aggr)()){
            static foreach (p; processors){
                static if (p.canHandle!(aggr)()){
                    p.handle!(aggr)(internals);
                }
            }
        }
    }
    
    private static bool qualifiesForTracking(alias T)(){
        return hasAnnotation!(T, Tracked);
    }
}
