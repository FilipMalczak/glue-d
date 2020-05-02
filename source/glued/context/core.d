module glued.context.core;

import std.meta;
import std.traits;
import std.typecons;
import std.range;

import glued.stereotypes;
import glued.mirror;
import glued.codescan.unrollscan;
import glued.logging;

import glued.context.typeindex: InheritanceIndex;
import glued.context.processors;
import glued.context.bundles;

import dejector;

struct CompositeProcessor(Processors...) if (allSatisfy!(P => is(P: Processor) && __traits(compiles, new P()))) {
    private Tuple!(Processors) processors;
    
    this(GluedInternals internals){
        static foreach (i, P; Processors){
            processors[i] = new P();
            processors[i].init(internals);
        }
    }
    
    void beforeScan(){
        static foreach (i; Processors.length.iota) {
            processors[i].beforeScan();
        }   
    }
    
    void handleType(A)(){
        static foreach (i; Processors.length.iota) {
            processors[i].handleType!(A)();
        }
    }
    
    void handleBundle(string modName)(){
        static foreach (i; Processors.length.iota)
            processors[i].handleBundle!(modName)();
    }
    
    void afterScan(){
        static foreach (i; Processors.length.iota)
            processors[i].afterScan();
    }
    
    void onContextFreeze(){
        static foreach (i; Processors.length.iota)
            processors[i].onContextFreeze();
    }
    
    //todo before-/afterScannable
}

class GluedContext(Processors...) {
    private GluedInternals internals;
    mixin CreateLogger;
    private Logger log;
    private bool _frozen = false; //todo expose

    CompositeProcessor!Processors processor;

    @property //fixme should it be private?
    private LogSink logSink(){
        return internals.logSink;
    }

    this(LogSink logSink){
        this.log = Logger(logSink);
        internals = GluedInternals(new Dejector(), logSink, new InheritanceIndex(logSink), new BundleRegistrar());
        this.processor = CompositeProcessor!Processors(internals);
        internals.injector.bind!(Dejector)(new InstanceProvider(internals.injector));
        internals.injector.bind!(InheritanceIndex)(new InstanceProvider(internals.inheritanceIndex));
        internals.injector.bind!(LogSink)(new InstanceProvider(cast(Object) logSink));
        internals.injector.bind!(BundleRegistrar)(new InstanceProvider(cast(Object) internals.bundleRegistrar));
    }

    private void beforeScan(){
        processor.beforeScan();
    }

    private void afterScan(){
        processor.afterScan();
    }

    void scan(alias scannable)() if (isScannable!scannable)
    {
        //todo exception if frozen
        enum scanConsumer(string m, string n) = "track!(\""~m~"\", \""~n~"\")();";
        enum bundleConsumer(string modName) = "trackBundle!(\""~modName~"\")();";
        
        mixin unrollLoopThrough!(scannable, "void doScan() { ", scanConsumer, bundleConsumer, "}");
        log.info.emit("Before ", scannable);
        beforeScan();
        log.info.emit("Scanning ", scannable);
        doScan();
        log.info.emit("After ", scannable);
        afterScan();
        log.info.emit("Scan of ", scannable, " finished");
    }
    
    void freeze(){
        assert(!_frozen); //todo exception (or maybe it should be idempotent?)
        _frozen = true;
        processor.onContextFreeze();
    }

    @property
    Dejector injector(){
        return internals.injector;
    }
    
    //todo do I really want to expose this?
    auto get(T)(){
        return injector.get!T;
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
            processor.handleType!aggr();
        }
    }

    void trackBundle(string modName)(){
        processor.handleBundle!modName();
    }

    private static bool qualifiesForTracking(alias T)(){
        return hasAnnotation!(T, Tracked);
    }

}

alias DefaultGluedContext = GluedContext!(ConcreteTypesProcessor, InterfaceProcessor, BundlesProcessor);
