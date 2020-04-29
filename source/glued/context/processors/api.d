module glued.context.processors.api;

import glued.logging: LogSink;

import glued.context.bundles: BundleRegistrar;
import glued.context.typeindex: InheritanceIndex;

import dejector: Dejector;

struct GluedInternals {
    Dejector injector;
    LogSink logSink;
    InheritanceIndex inheritanceIndex;
    BundleRegistrar bundleRegistrar;
}

interface Processor {
    void before(GluedInternals internals);
    
    void after(GluedInternals internals);
    
    void onContextFreeze(GluedInternals internals);
    
    void handle(A)(GluedInternals internals);
}

//fixme not really an api

import glued.logging;

mixin template RequiredProcessorCode() {
    mixin CreateLogger;
    Logger log;
    
    this(LogSink sink){
        log = Logger(sink);
    }
}
