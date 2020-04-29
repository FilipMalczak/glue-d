module glued.context.core;

import std.meta;
import std.traits;
import std.typecons;
import std.range;

import glued.stereotypes;
import glued.mirror;
import glued.scan;
import glued.logging;

import glued.context.typeindex: InheritanceIndex;
import glued.context.processors;
import glued.context.bundles;

import dejector;

struct CompositeProcessor(Processors...) {// if allSatisfy!(P => is(P: Processor) && __traits(compiles, new P(cast(LogSink) null)){ //todo
    private Tuple!(Processors) processors;
    
    this(LogSink sink){
        static foreach (i, P; Processors){
            processors[i] = new P(sink);
        }
    }
    
    void beforeScan(GluedInternals internals){
        static foreach (i; Processors.length.iota)
            processors[i].beforeScan(internals);
    }
    
    void afterScan(GluedInternals internals){
        static foreach (i; Processors.length.iota)
            processors[i].afterScan(internals);
    }
    
    void onContextFreeze(GluedInternals internals){
        static foreach (i; Processors.length.iota)
            processors[i].onContextFreeze(internals);
    }
    
    void handle(A)(GluedInternals internals){
        static foreach (i; Processors.length.iota)
            processors[i].handle!(A)(internals);
    }
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
        this.processor = CompositeProcessor!Processors(logSink);
        internals = GluedInternals(new Dejector(), logSink, new InheritanceIndex(logSink), new BundleRegistrar());
        internals.injector.bind!(Dejector)(new InstanceProvider(internals.injector));
        internals.injector.bind!(InheritanceIndex)(new InstanceProvider(internals.inheritanceIndex));
        internals.injector.bind!(LogSink)(new InstanceProvider(cast(Object) logSink));
        internals.injector.bind!(BundleRegistrar)(new InstanceProvider(cast(Object) internals.bundleRegistrar));
    }

    private void beforeScan(){
        processor.beforeScan(internals);
    }

    private void afterScan(){
        processor.afterScan(internals);
    }

    void scan(alias scannables)(){
        //todo exception if frozen
        enum scanConsumer(string m, string n) = "track!(\""~m~"\", \""~n~"\")();";
        enum bundleConsumer(string modName) = "trackBundle!(\""~modName~"\")();";
        mixin unrollLoopThrough!(scannables, "void doScan() { ", scanConsumer, bundleConsumer, "}");

        log.info.emit("Before ", scannables);
        beforeScan();
        log.info.emit("Scanning ", scannables);
        doScan();
        log.info.emit("After ", scannables);
        afterScan();
        log.info.emit("Scan of ", scannables, " finished");
    }
    
    void freeze(){
        assert(!_frozen); //todo exception (or maybe it should be idempotent?)
        _frozen = true;
        processor.onContextFreeze(internals);
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
            processor.handle!aggr(internals);
        }
    }

    //todo this needs to go to some processor, I think
    void trackBundle(string modName)(){
        log.info.emit("Tracking glue-d bundle for module "~modName);
        internals.bundleRegistrar.register!(modName)();
    }

    private static bool qualifiesForTracking(alias T)(){
        return hasAnnotation!(T, Tracked);
    }

}

alias DefaultGluedContext = GluedContext!(ConcreteTypesProcessor, InterfaceProcessor);
