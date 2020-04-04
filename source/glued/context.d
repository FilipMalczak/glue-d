module glued.context;

import std.variant;

import poodinis: DependencyContainer;

import glued.stereotypes;
import glued.mirror;
import glued.scan;

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

synchronized class GluedContext {
    private shared(DependencyContainer) _internalContext;
    
    
    
    this(){
        _internalContext = new shared DependencyContainer();
    }
    
    void scan(alias scannables)(){
        enum scanConsumer(string m, string n) = "track!(\""~m~"\", \""~n~"\")();";
       
        mixin unrollLoopThrough!(scannables, "void doScan() { ", scanConsumer, "}");
        
        doScan();
    }
    
    @property
    shared(DependencyContainer) internalContext(){
        return _internalContext;
    }
    
    void track(string m, string n)(){
        version(glued_debug) {
            pragma(msg, "Tracking ", m, "::", n);
        }
        alias aggr = import_!(m, n);
        static if (qualifiesForTracking!(aggr)()){
            alias target = TargetTypeOf!aggr;
            enum isComponent = hasAnnotation!(aggr, Component);
            version(glued_debug) {
                import std.conv;
                pragma(msg, "  which qualifies as ", (isComponent?"component":"configuration"), " of target ", to!string(target));
            }
            static if (isComponent && target == Target.Type.CLASS)
                trackComponentClass!(aggr)();
        }
    }
    
    private void trackComponentClass(X)() {
        import std.stdio;
        import std.traits;
        writeln("registering ", fullyQualifiedName!X);
        _internalContext.register!X;
    }
    
    private static bool qualifiesForTracking(alias T)(){
        return hasAnnotation!(T, Component) || hasAnnotation!(T, Configuration);
    }
}
