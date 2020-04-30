module glued.context.processors.api;

public import glued.scannable: Scannable, isScannable;

import glued.logging: LogSink;

import glued.context.bundles: BundleRegistrar;
import glued.context.typeindex: InheritanceIndex;

import dejector: Dejector;

struct GluedInternals {
    Dejector injector;
    //todo these all can be resolved via injector...
    LogSink logSink;
    InheritanceIndex inheritanceIndex;
    BundleRegistrar bundleRegistrar;
}

interface Processor {
    void init(GluedInternals);

    void beforeScan();
    
    void beforeScannable(alias scannable)() if (isScannable!scannable);
    
    void handleType(A)();
    
    void handleBundle(string modName)();
    
    void afterScannable(alias scannable)() if (isScannable!scannable);
    
    void afterScan();
    
    void onContextFreeze();
}

//fixme not really an api

import glued.logging;


mixin template ProcessorSetup() {
    mixin CreateLogger;
    private Logger log;
    private GluedInternals internals;
    
    void init(GluedInternals i){
        this.internals = i;
        this.log = Logger(i.logSink);
    }
}
