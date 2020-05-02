module glued.codescan.scanner;

import std.meta;

import glued.codescan.unrollscan;
public import glued.codescan.listener;
public import glued.codescan.scannable;

import glued.logging;
import glued.mirror;

class CodebaseScanner(State, Listeners...) 
//    if (__traits(compiles, new CompositeListener!(State, Listeners)()))  //todo?
{   
    mixin CreateLogger;
    private Logger log;
    private bool _frozen = false;
    private CompositeListener!(State, Listeners) listener = new CompositeListener!(State, Listeners);
    
    this(State initialState, LogSink sink=new VoidSink) {
        log = Logger(sink);
        log.info.emit("Initializing scan listeners with ", initialState);
        listener.init(initialState);
    }
    
    void scan(alias scannable)()
        if (isScannable!(scannable))
    { 
        //todo assert not frozen
        //todo if we move these into private methods, we can log.trace whats going on
        enum typeConsumer(string m, string n) = "listener.onType!(import_!(\""~m~"\", \""~n~"\"))();";
        enum bundleConsumer(string modName) = "listener.onBundleModule!(\""~modName~"\")();";
        
        mixin unrollLoopThrough!(scannable, "void doScan() { ", typeConsumer, bundleConsumer, "}");
        listener.onScannable!(scannable)();
        log.info.emit("Scanning ", scannable);
        doScan();
        log.info.emit("Scan of ", scannable, " finished");
    }
    
    void freeze(){
        log.info.emit("Freezing scanner");
        _frozen = true;
        listener.onScannerFreeze();
    }
    
    @property
    bool frozen(){
        return _frozen;
    }
}


