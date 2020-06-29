module glued.application.logging;

import std.functional;

import glued.logging;
import glued.pathtree;

import optional;

alias Predicate(T) = bool delegate(T);
alias Callable(T) = void delegate(T);

class FilteringSink: LogSink {
    private LogSink wrapped;
    private Predicate!LogEvent predicate;
    private Optional!(Callable!LogEvent) discardedConsumer;
    
    this(LogSink wrapped, Predicate!LogEvent predicate){
        this.wrapped = wrapped;
        this.predicate = predicate;
        this.discardedConsumer = no!(Callable!LogEvent);
    }
    
    this(LogSink wrapped, Predicate!LogEvent predicate, Callable!LogEvent discardedConsumer){
        this.wrapped = wrapped;
        this.predicate = predicate;
        this.discardedConsumer = discardedConsumer.some;
    }
    
    void consume(LogEvent e){
        if (predicate(e)) {
            wrapped.consume(e);
        } else {
            if (!discardedConsumer.empty){
                (discardedConsumer.front())(e);
            }
        }
    }
}

alias PathExtractor = Path delegate(LogEvent);

struct ModuleExtractors {
    @property
    static PathExtractor fromLogger() { return toDelegate((LogEvent e) => Path.parse(e.loggerLocation.moduleName)); }
    @property
    static PathExtractor fromEvent() { return toDelegate((LogEvent e) => Path.parse(e.eventLocation.moduleName)); }
}

Predicate!LogEvent levelConfig(PathTreeView!Level config, PathExtractor extractor=ModuleExtractors.fromEvent, Level defaultLevel=Level.ANY){
    return (LogEvent e) => (e.level >= config.get(extractor(e)).or(defaultLevel.some).front());
}

//todo another source set
//todo this is an awfully trivial test suite, extend it
version(unittest){
    import std.datetime: SysTime;
    import std.concurrency: Tid;

    enum ActionTaken { UNKNOWN, CONSUMED, DISCARDED }
    
    auto event(string loggerModule, string eventModule, Level lvl){
        return LogEvent(
            lvl, 
            CodeLocation("", 0, loggerModule, "", "", ""),
            CodeLocation("", 0, eventModule, "", "", ""),
            "",
            no!SysTime,
            no!Tid
        );
    }
    
    ActionTaken whenFilteredWithPredicate(Predicate!LogEvent pred, LogEvent e){
        ActionTaken action = ActionTaken.UNKNOWN;
        class Consume: LogSink { 
            void consume(LogEvent e){
                action = ActionTaken.CONSUMED;
            }
        }
        void discard(LogEvent e){ action = ActionTaken.DISCARDED; }
        new FilteringSink(new Consume, pred, &discard).consume(e);
        return action;
    }
}

unittest {
    assert(
        whenFilteredWithPredicate(
            levelConfig(
                new ConcretePathTree!Level, 
                ModuleExtractors.fromEvent,
                Level.ANY
            ), 
            event("a", "b", Level.INFO)
        ) 
        ==
        ActionTaken.CONSUMED
    );
    assert(
        whenFilteredWithPredicate(
            levelConfig(
                new ConcretePathTree!Level, 
                ModuleExtractors.fromEvent,
                Level.INFO
            ), 
            event("a", "b", Level.DEBUG)
        ) 
        ==
        ActionTaken.DISCARDED
    );
}
