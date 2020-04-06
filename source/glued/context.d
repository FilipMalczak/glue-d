module glued.context;

import std.variant;
import std.meta;
import std.traits;

import poodinis: DependencyContainer;

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

//struct Processor { 
//    string canHandle="canHandle"; 
//    string handle="handle";
//    string before="";
//    string after="";
//}

////todo this seems well suited for annotations module
//template ResolveMemberAnnotation(alias T, A, string fromField="value") {
//    static if (!hasOneAnnotation!(T, A)){
//        enum ResolveMemberAnnotation = None();
//    } else {
//        //todo actually member name
//        enum methodName = __traits(getMember, getAnnotation!(T, A), fromField);
//        static if (methodName.length == 0){
//            enum ResolveMemberAnnotation = None();
//        }
//        else
//        {
//            static if (!hasMember!(T, methodName)){
//                enum ResolveMemberAnnotation = None();
//            } else {
//                pragma(msg, "resolved ", T, ":", A, "/", fromField, " to ", methodName);
//                alias ResolveMemberAnnotation = __traits(getMember, T, methodName);
//            }
//        }
//        
//    }
//}

//version(unittest){
//    @Processor
//    class P {
//        bool canHadle(S)(){
//            return true;
//        }
//        
//        void handle(S)(GluedInternals internals){
//            pragma(msg, "Handle ", S);
//        }
//    }
//}

//@Processor
//class SimpleDiProcessor {
//    enum canHandle(A) = isMarkedAsStereotype!(A, Component);
//    
//    void handle(TypeWithStereotype)(GluedInternals internals){
//        import std.stdio;
//        import std.traits;
//        writeln("registering ", fullyQualifiedName!TypeWithStereotype);
//        internals.diContext.register!TypeWithStereotype;
//    }
//}

/**
 * Interface of each processing step; not enforced, because it has to be templated,
 * but is useful for documentational usage.
 */
//interface Processor {
//    void before();
//    bool canHadle(A)();
//    void handle(A)(GluedInternals internals);
//    void after();
//}

struct SimpleDiProcessor {
    static void before(){}
    
    static bool canHandle(A)(){
        pragma(msg, "canHandle ", A, " -> ", isMarkedAsStereotype!(A, Component), " ; ", getStereotype!(A, Component));
        return is(A == class) && isMarkedAsStereotype!(A, Component);
    }
    
    static void handle(A)(GluedInternals internals){
        import std.stdio;
        import std.traits;
        writeln("registering ", fullyQualifiedName!A);
        internals.diContext.register!A;
    }
    
    static void after(){}
}

struct GluedInternals {
    shared DependencyContainer diContext;
}

synchronized class GluedContext {
    private GluedInternals internals;
    
    alias processors = AliasSeq!(SimpleDiProcessor);
    
    this(){
        internals = GluedInternals(new shared DependencyContainer());
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
