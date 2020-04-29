module glued.application.impl;

import glued.logging;
import glued.context;

import glued.application.logging;


interface ApplicationAction {
    void execute();
}

interface ShutdownHandler {
    void onShutdown();
}

class GluedRuntime(alias scannables) {
    mixin CreateLogger;
    Logger log;

    private DefaultGluedContext context;

    void start(string[] cmdLineArgs){
        DeferredLogSink sink = new DeferredLogSink;
        log = Logger(sink);
        log.debug_.emit("Initialized deferred log sink, setting up context");
        context = new DefaultGluedContext(sink); //todo you really need to clean up the processors abstraction...
        log.debug_.emit("Context ready, scanning: ", scannables);
        context.scan!scannables();
        context.freeze(); //todo this will happen in different moment when we compose scannables from annotations
//        instantiateComponents(); //todo do this once you index types by stereotypes
//interface StereotypedInstance(S) {prop S stereotype, prop Object instance}
//interface StereotypeDescriptor{ prop string stereotypeTypeName }
        log.debug_.emit("Scan finished");
        resolveLogSink(sink); //todo if there is exception before this step, turn off any filtering (maybe keep buildLog.conf), flush to stderr, then let the failure propagate (so we can investigate, but with logs)
        runActions();
        log.info.emit("Runtime started");
    }
    
    private void resolveLogSink(DeferredLogSink sink){
        sink.resolve(new StdoutSink); //todo
    }
    
    private void runActions(){
        InterfaceResolver resolver = context.get!InterfaceResolver;
        auto actions = resolver.getImplementations!(ApplicationAction)();
        log.debug_.emit("Found ", actions.length, " actions to execute");
        foreach(a; actions){ //todo make optionally parallel via glued.app.actions.parallel
            a.execute();
        }
    }
    
    @property
    auto currentContext(){
        return context; //todo optional?
    }
    
    void shutDown(){
        log.debug_.emit("Shutdown started");
        InterfaceResolver resolver = context.get!InterfaceResolver;
        
        ShutdownHandler[] handlers = resolver.getImplementations!ShutdownHandler;
        log.debug_.emit("Found ", handlers.length, " shutdown handlers");
        foreach(h; handlers){ //todo ditto
            h.onShutdown();
        }
        context = null;
        log.info.emit("Runtime shut down");
    }
}
