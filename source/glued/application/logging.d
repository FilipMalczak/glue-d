module glued.application.logging;

import glued.logging;

class DeferredLogSink: LogSink {
    private LogEvent[] _deferred;
    private LogSink _delegate = null;
    
    void consume(LogEvent e){
        if (_delegate is null){
            _deferred ~= e;
        } else {
            _delegate.consume(e);
        }
    }
    
    @property
    bool resolved(){
        return _delegate !is null;
    }
    
    void resolve(LogSink sink){
        if (_delegate is null){
            _delegate = sink;
            flushDeferred();
        } else {
            assert(false); //todo exception
        }
    }
    
    private void flushDeferred(){
        foreach (e; _deferred)
            _delegate.consume(e);
        _deferred = [];
    }
}
