module glued.logging;

import std.conv;
import std.traits;
import std.algorithm;
import std.range;
import std.datetime;
import optional;

enum Module;

enum Level {
    ANY,
    TRACE,
    DEBUG,
    INFO,
    WARN,
    ERROR,
    NONE
}

immutable maxLevelNameLength = (cast(Level[]) [ EnumMembers!Level ]).maxElement!"to!string(a).length".to!string.length;

string defaultSinkGenerator(string name, alias loggerLocation)(){
//    static if (loggerLocation.codeContext == CodeContext.AGGREGATE) {
    static if (loggerLocation.aggregateName && !loggerLocation.functionName) {
        return "import glued.context: Autowire; import glued.logging: LogSink; @Autowire LogSink "~name~";";
    }
    result =  "static if (__traits(compiles, injector)){\n";
    result ~= "    import glued.logging: LogSink; LogSink "~name~" = injector.get!LogSink;\n";
    result ~= "} else {\n";
    result ~= "    import glued.logging: LogSink, DefaultRuntimeSink; LogSink "~name~" = new DefaultRuntimeSink;";
    result ~= "}";
    return result;
}

string cutDown(string s, size_t len){
    return s[0..min(len, s.length)];
}

string format(LogEvent e){
    import std.string;
    string lvl = to!string(e.level).center(maxLevelNameLength+2, ' ');
    return ( e.timestamp.empty ? 
        "STATIC".center(25, ' ') : 
        e.timestamp.front().to!string.cutDown(25).leftJustify(25, ' ')
     ) ~ " [ " ~ lvl ~ " ] :: "~e.loggerLocation.path.leftJustify(40, ' ')~"@"~to!string(e.eventLocation.line)~" | "~to!string(e.message);
}

struct DefaultStaticSink {
    import std.array;
    import std.conv;

    static string consumer(alias e)(){ // LogEvent e
        string versionToEnable = "debug_"~(e.loggerLocation.moduleName.replace(".", "_"));
        return "version("~versionToEnable~"){ pragma(msg, format(e)); }";
    }

    static void consume(LogEvent e)(){
        mixin(consumer!(e)());
    }
}

interface LogSink {
    void consume(LogEvent e);
}

class StdoutSink: LogSink {
    import std.stdio;
        
    override void consume(LogEvent e){
        stdout.writeln(format(e));
    }
}

struct LoggerConfig(_StaticLogSink){
    alias StaticLogSink = _StaticLogSink;
    bool figureOutEventAggregate=true;
}

enum DefaultConfig = LoggerConfig!(DefaultStaticSink)();


struct CodeLocation {
    string filename;
    int line;
    string moduleName;
    string aggregateName;
    string functionName;
    string prettyFunctionName;

    @property
    string path(){
        if (functionName.length)
            return functionName;
        if (aggregateName.length)
            return aggregateName;
        if (moduleName.length)
            return moduleName;
        assert(false);
    }
}


struct LogEvent {
    Level level;
    CodeLocation loggerLocation;
    CodeLocation eventLocation;
    string message;
    
    Optional!SysTime timestamp;
}

mixin template CreateLogger(alias config=DefaultConfig, string f=__FILE__, int l=__LINE__, string m=__MODULE__, string foo=__FUNCTION__,  string prettyFoo=__PRETTY_FUNCTION__){
    static if (__traits(compiles, typeof(this))){
        alias Here = typeof(this);
    } else {
        alias Here = Module;
    }
    
    struct Logger {
        import std.traits: fullyQualifiedName;
        import std.meta: staticMap;
        import std.conv: to;
        import std.string: join;
        import std.algorithm: startsWith;
        import std.array: split;
        
        private LogSink logSink;
        
        @property
        static CodeLocation location(){
            static if (is(Here == Module)){
                return CodeLocation(f, l, m, "", foo, prettyFoo);
            } else {
                return CodeLocation(f, l, m, fullyQualifiedName!Here, foo, prettyFoo);
            }
        }
        
        static LogEvent event(Level level, string message, CodeLocation eventLocation, bool figureOutEventAggregate=true){
            if (figureOutEventAggregate) {
                if (location.moduleName == eventLocation.moduleName && 
                    location.aggregateName && eventLocation.functionName && 
                    eventLocation.functionName.startsWith(location.aggregateName)){
                        eventLocation.aggregateName = eventLocation.functionName.split(".")[0..$-1].join(".");
                }
            }
            if (__ctfe){
                return LogEvent(level, location, eventLocation, message, no!SysTime);
            } else {
                return LogEvent(level, location, eventLocation, message, Clock.currTime().some);
            }
        }
        
        struct LogClosure(string f=__FILE__, int l=__LINE__, string m=__MODULE__, string foo=__FUNCTION__,  string prettyFoo=__PRETTY_FUNCTION__) {
            void Emit(Level level, T...)(){
                config.StaticLogSink.consume!(event(level, msg!T, CodeLocation(f, l, m, "", foo, prettyFoo), config.figureOutEventAggregate))();
            }
        }
        
        static auto Log(string f=__FILE__, int l=__LINE__, string m=__MODULE__, string foo=__FUNCTION__,  string prettyFoo=__PRETTY_FUNCTION__)(){
            return LogClosure!(f, l, m, foo, prettyFoo)();
        }
        
        //todo private
        mixin template StaticLevelMixin(string method, string member){
            mixin("struct "~method~"Closure(string f=__FILE__, int l=__LINE__, string m=__MODULE__, string foo=__FUNCTION__,  string prettyFoo=__PRETTY_FUNCTION__) {
                void Emit(T...)(){
                    Log!(f, l, m, foo, prettyFoo).Emit!(Level."~member~", T);
                }
            }");
            mixin("@property static auto "~method~"(string f=__FILE__, int l=__LINE__, string m=__MODULE__, string foo=__FUNCTION__,  string prettyFoo=__PRETTY_FUNCTION__)(){
            return "~method~"Closure!(f, l, m, foo, prettyFoo)();
        }");
        }
       
        
        struct logClosure(string f=__FILE__, int l=__LINE__, string m=__MODULE__, string foo=__FUNCTION__,  string prettyFoo=__PRETTY_FUNCTION__) {
            LogSink logSink;
        
            void emit(T...)(Level level, T t){
                logSink.consume(event(level, text(t), CodeLocation(f, l, m, "", foo, prettyFoo), config.figureOutEventAggregate));
            }
        }
        
        @property
        auto log(string f=__FILE__, int l=__LINE__, string m=__MODULE__, string foo=__FUNCTION__,  string prettyFoo=__PRETTY_FUNCTION__)(){
            return logClosure!(f, l, m, foo, prettyFoo)(logSink);
        }
        
        //todo private
        mixin template RuntimeLevelMixin(string method, string member){
            mixin("struct "~method~"Closure(string f=__FILE__, int l=__LINE__, string m=__MODULE__, string foo=__FUNCTION__,  string prettyFoo=__PRETTY_FUNCTION__) {
                Logger logger;
            
                void emit(T...)(T t){
                    logger.log!(f, l, m, foo, prettyFoo)().emit(Level."~member~", t);
                }
            }");
            mixin("@property 
        auto "~method~"(string f=__FILE__, int l=__LINE__, string m=__MODULE__, string foo=__FUNCTION__,  string prettyFoo=__PRETTY_FUNCTION__)(){
            return "~method~"Closure!(f, l, m, foo, prettyFoo)(this);
        }");
        }
        
        mixin template LevelMixin(string staticMethod, string runtimeMethod, string member){
            mixin StaticLevelMixin!(staticMethod, member);
            mixin RuntimeLevelMixin!(runtimeMethod, member);
        }
        
        
        private struct Triple { string s, r, m; }
        
        static foreach (t; [
                Triple("Error", "error", "ERROR"),
                Triple("Warn", "warn", "WARN"),
                Triple("Info", "info", "INFO"),
                Triple("Debug", "debug_", "DEBUG"),
                Triple("Trace", "trace", "TRACE")
            ]){
            mixin LevelMixin!(t.s, t.r, t.m);
        }
    
        static string msg(T...)(){
            string asString(X...)(){
                static if (is(X)){
                    return fullyQualifiedName!X;
                } else static if (is(typeof(X))){
                    return to!string(X);
                } else {
                    static assert(false); //no support yet
                }
            }
            string fold(int i, string acc)(){
                static if (i<T.length){
                    return fold!(i+1, asString!(T[i])~acc)();
                } else {
                    return acc;
                }
            }
            return fold!(0, "")();
        }
        
        struct LoggedClosure(string f=__FILE__, int l=__LINE__, string m=__MODULE__, string foo=__FUNCTION__,  string prettyFoo=__PRETTY_FUNCTION__) {
            string value(string s)(){
                Info!(f, l).Emit!("mixing in: \n"~s);
                return s;
            }
        }
        
        @property
        static auto logged(string f=__FILE__, int l=__LINE__, string m=__MODULE__, string foo=__FUNCTION__,  string prettyFoo=__PRETTY_FUNCTION__)(){
            return LoggedClosure!(f, l, m, foo, prettyFoo)();
        }
    }
}

version(unittest){
    version = debug_glued_logging;
}

version(unittest){
    mixin CreateLogger!();
    
    class C {
        mixin CreateLogger!();

        static auto log = Logger(new StdoutSink);
        
        mixin(Logger.logged.value!("pragma(msg, \"yellow\");"));
        
        static void foo(){
            mixin CreateLogger!();
            Logger.Info.Emit!"HEY";
            log.info.emit("hey");
        }
        
        void bar(string a){
            mixin CreateLogger!();
            
            Logger.Info.Emit!"HO";
        }
    }
    
    interface I {
        mixin CreateLogger!();
    }
    
    void baz(){
        mixin CreateLogger!();
        auto log = Logger(new StdoutSink);
        log.Debug.Emit!"VAZ";
    }
    
    void testFoo(){
        LogSink logSink = new StdoutSink;
        mixin CreateLogger!();
        Logger.Info.Emit!"XYZ";
        Logger(new StdoutSink).info().emit("123");
    }
}

//todo tests to dedicated dir
//todo it all works on StdoutSink and default static sink; test it on some event collector, analyze events post mortem
unittest {
    Logger.Info.Emit!("Foo ")();
    Logger(new StdoutSink).info().emit("howdy");
    C.Logger.Debug.Emit!"Something";
    C.foo();
    C.log.debug_.emit("hey");
}
unittest {
    new C().bar("");
    I.Logger.Info.Emit!"XXX";
    baz();
}

unittest{
    testFoo();
}
