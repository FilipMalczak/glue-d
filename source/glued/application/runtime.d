module glued.application.runtime;

import std.range;
import std.functional;

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

enum RuntimeLifecycleStage {
    PREPARED,
    STARTED,
    SHUT_DOWN
}

class GluedRuntime(alias scannables) {
    mixin CreateLogger;
    private Logger log;

    private RuntimeLifecycleStage _stage = RuntimeLifecycleStage.PREPARED;
    private Dejector _injector;
    private LogSink _targetSink;
    
    @property
    RuntimeLifecycleStage currentStage(){
        return _stage;
    }
    
    @property
    auto injector(){
        return _injector; //todo optional?
    }
    
    @property
    auto targetSink(){
        return _targetSink;
    }
    
    //todo expose effective-/configuredSink? the deferred one, or only the filtering one?
    
    @property
    void targetSink(LogSink sink){
        assert(_stage == RuntimeLifecycleStage.PREPARED); //todo exception
        _targetSink = sink;
    }
    
    void start(string[] cmdLineArgs=[]){
        assert(_stage == RuntimeLifecycleStage.PREPARED); //todo exception
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
        log.debug_.emit("Resolving log sink based on loaded configuration");
        resolveLogSink(sink); //todo if there is exception before this step, turn off any filtering (maybe keep buildLog.conf), flush to stderr, then let the failure propagate (so we can investigate, but with logs)
        //        instantiateComponents(); //todo do this once you index types by stereotypes
//interface StereotypedInstance(S) {prop S stereotype, prop Object instance}
//interface StereotypeDescriptor{ prop string stereotypeTypeName }
        log.debug_.emit("Running application actions");
        runActions();
        log.info.emit("Runtime started");
        _stage = RuntimeLifecycleStage.STARTED; //todo on exception -> SHUT_DOWN
    }
    
    //todo test this by providing some small app with bunch of components; provide glued assets for their log levels, steer some with build time assets too; set targetSink manually, provide action that triggers these components methods (which do logging) and make sure that related events are prezent
    private void resolveLogSink(DeferredLogSink sink){
    //todo ugly leftover
//        auto logFilteringTree = _injector
//            .get!Config
//            .view
//            .subtree("log.level")
//            .mapValues!Level(toDelegate((ConfigEntry v) => v.text.toLevel));
        if (_targetSink is null)
            _targetSink = new StdoutSink; //todo build sink based on config (stdout/err, some storage, maybe composites?); what to do if _targetSink !is null?
        //todo levelConfig can also be tweaked via config
        //todo ugly leftover
        //auto filteringSink = new FilteringSink(_targetSink, levelConfig(logFilteringTree));
        auto filteringSink = new FilteringSink(_targetSink, x => true);
        sink.resolve(filteringSink);
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
    
    void shutDown(){
        assert(_stage == RuntimeLifecycleStage.STARTED); //todo exception
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
        _stage = RuntimeLifecycleStage.SHUT_DOWN;
    }
}
