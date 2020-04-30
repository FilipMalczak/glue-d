module glued.context.processors.bundles;

import glued.logging;

import glued.context.processors.api;

class BundlesProcessor: Processor {
    mixin ProcessorSetup;

    void beforeScan() {}
    
    void beforeScannable(alias scannable)() if (isScannable!scannable) {}
    
    void handleType(A)() {}
    
    void handleBundle(string modName)() {
        log.info.emit("Tracking glue-d bundle for module "~modName);
        internals.bundleRegistrar.register!(modName)();
    }
    
    void afterScannable(alias scannable)() if (isScannable!scannable) {}
    
    void afterScan() {}
    
    void onContextFreeze() {}
}
