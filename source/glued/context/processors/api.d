module glued.context.processors.api;

public import glued.scannable: Scannable, isScannable;

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

//todo maybe lets pass sink and internals as properties or with init method?
interface Processor {
    void beforeScan(GluedInternals internals);
    
    //fixme unused yet
    void beforeScannable(alias scannable)(GluedInternals internals) if (isScannable!scannable);
    
    void handleType(A)(GluedInternals internals);
    
    void handleBundle(string modName)(GluedInternals internals);
    
    //fixme unused yet
    void afterScannable(alias scannable)(GluedInternals internals) if (isScannable!scannable);
    
    void afterScan(GluedInternals internals);
    
    void onContextFreeze(GluedInternals internals);
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
