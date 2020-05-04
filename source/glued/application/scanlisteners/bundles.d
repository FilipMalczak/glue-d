module glued.application.scanlisteners.bundles;

import std.algorithm;
import std.path;
import std.array;

import glued.logging;

//todo listener should public import scannable
import glued.codescan.scannable;
import glued.codescan.listener;

import glued.adhesives.bundles;
import glued.adhesives.config;

import dejector;

///from top-level paths towards lower-level ones; if depth is the same, alphabetical order
auto assetComparator(Asset a, Asset b){
    auto aDepth = a.path.depth;
    auto bDepth = b.path.depth;
    if (aDepth == bDepth)
    {
        auto aName = a.path.baseName;
        auto bName = b.path.baseName;
        return cmp(aName, bName) < 0;
    }
    else
    {
        return aDepth < bDepth;
    }
}

class BundlesListener: ScanListener!Dejector 
{
    mixin CreateLogger;
    private Logger log;
    private Dejector injector;
    private BundleRegistrar registrar;
    private Config config;

    void init(Dejector injector)
    {
        this.injector = injector;
        log = Logger(injector.get!LogSink);
        registrar = new BundleRegistrar;
        config = new Config(injector.get!LogSink);
        injector.bind!(BundleRegistrar)(new InstanceProvider(registrar));
        injector.bind!(Config)(new InstanceProvider(config));
        registrar.register(new BuildTimeBundle);
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
        registrar.register!(modName)();
    }
    
    void onScannerFreeze()
    {
        auto configAssets = registrar
            .ls()
            .filter!(a => 
                a.path.baseName == "logging.conf" ||
                a.path.baseName == "application.conf"
            );
        
        //1. scheme=glued
        //sort from top-level packages towards lower ones
        auto gluedAssets = configAssets
            .filter!(a => a.scheme == "glued")
            .array //required so that result of prev step is random access range
            .sort!(assetComparator);
        foreach (a; gluedAssets)
            config.feed(a);
        
        //2. scheme=build
        //order defined in bundles adhesive
        foreach(n; buildTimeAssetNames)
        {
            auto a = registrar.find("build", n);
            if (!a.empty)
            {
                config.feed(a.front());
            }
        }

        //3. others
        //ditto when it comes to sorting
        auto otherAssets = configAssets
            .filter!(a => a.scheme != "glued" && a.scheme != "build")
            .array //required so that result of prev step is random access range
            .sort!(assetComparator);
        foreach (a; otherAssets)
            config.feed(a);
        
        //TODO 4. files specified with CLI, in the order of specifying
    }
}
