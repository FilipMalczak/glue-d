module glued.application.scanlisteners.bundles;

import glued.logging;

//todo listener should public import scannable
import glued.codescan.scannable;
import glued.codescan.listener;

import glued.adhesives.bundles;

import dejector;

class BundlesListener: ScanListener!Dejector 
{
    mixin CreateLogger;
    private Logger log;
    private Dejector injector;
    private BundleRegistrar registrar;

    void init(Dejector injector)
    {
        this.injector = injector;
        log = Logger(injector.get!LogSink);
        registrar = new BundleRegistrar;
        injector.bind!(BundleRegistrar)(new InstanceProvider(registrar));
    }

    void onScannable(alias scannable)() if (isScannable!scannable)
    {
        //todo track what scannable does asset come from
    }
    
    void onType(T)()
    {
    }
    
    void onBundleModule(string modName)()
    {
        log.info.emit("Tracking glue-d bundle for module "~modName);
        internals.bundleRegistrar.register!(modName)();
    }
    
    void onScannerFreeze()
    {
    }
}
