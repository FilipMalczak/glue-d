module glued.context.core;

import std.meta;
import std.traits;

import glued.stereotypes;
import glued.mirror;
import glued.scan;
import glued.logging;

import glued.context.typeindex: InheritanceIndex;
import glued.context.processors;

import dejector;

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
