module glued.application.impl;

import std.range;

import glued.logging;

import glued.codescan;

import glued.application.scanlisteners;
import glued.application.logging;
import glued.adhesives;

import dejector;

interface ApplicationAction {
    void execute();
}

interface ShutdownHandler {
    void onShutdown();
}

class GluedRuntime(alias scannables) {
    mixin CreateLogger;
    Logger log;

    private Dejector _injector;

    void start(string[] cmdLineArgs){
        DeferredLogSink sink = new DeferredLogSink;
        log = Logger(sink);
        log.debug_.emit("Initialized deferred log sink");
        log.debug_.emit("Setting up DI facilities");
        _injector = new Dejector;
        _injector.bind!(LogSink)(new InstanceProvider(sink));
        auto scanner = new CodebaseScanner!(Dejector, GluedAppListeners)(_injector, sink);
        log.debug_.emit("Scanning: ", scannables);
        scanner.scan!scannables();
        log.debug_.emit("Scan finished, freezing application state");
        scanner.freeze(); //todo this will happen in different moment when we compose scannables from annotations
//        instantiateComponents(); //todo do this once you index types by stereotypes
//interface StereotypedInstance(S) {prop S stereotype, prop Object instance}
//interface StereotypeDescriptor{ prop string stereotypeTypeName }
        log.debug_.emit("Resolving log sink based on loaded configuration");
        resolveLogSink(sink); //todo if there is exception before this step, turn off any filtering (maybe keep buildLog.conf), flush to stderr, then let the failure propagate (so we can investigate, but with logs)
        log.debug_.emit("Running application actions");
        runActions();
        log.info.emit("Runtime started");
    }
    
    private void resolveLogSink(DeferredLogSink sink){
        sink.resolve(new StdoutSink); //todo
    }
    
    private void runActions(){
        InterfaceResolver resolver = _injector.get!InterfaceResolver;
        auto actions = resolver.getImplementations!(ApplicationAction)();
        if (!actions.empty) {
            log.debug_.emit("Found ", actions.length, " actions to execute");
            foreach(a; actions){ //todo make optionally parallel via glued.app.actions.parallel
                a.execute();
            }
        } else {
            log.debug_.emit("No actions found");
        }
    }
    
    @property
    auto injector(){
        return _injector; //todo optional?
    }
    
    void shutDown(){
        log.debug_.emit("Shutdown started");
        InterfaceResolver resolver = _injector.get!InterfaceResolver;
        
        ShutdownHandler[] handlers = resolver.getImplementations!ShutdownHandler;
        if (!handlers.empty) {
            log.debug_.emit("Found ", handlers.length, " shutdown handlers");
            foreach(h; handlers){ //todo ditto
                h.onShutdown();
            }
        } else {
            log.debug_.emit("No shutdown handlers found");
        }
        _injector = null;
        log.info.emit("Runtime shut down");
    }
}
