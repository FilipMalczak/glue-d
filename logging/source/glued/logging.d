module glued.logging;


import std.conv: to, text;
import std.traits: EnumMembers;
import std.algorithm: maxElement, min;

enum ___Module___;

enum Level {
    ANY,
    DEVELOPMENT,
    TRACE,
    DEBUG,
    INFO,
    WARN,
    ERROR,
    NONE
}

immutable maxLevelNameLength = (cast(Level[]) [ EnumMembers!Level ]).maxElement!"to!string(a).length".to!string.length;

string cutDown(string s, size_t len){
    return s[0..min(len, s.length)];
}

string enforceLength(string s, int maxLength){
    if (s.length > 40){
        s = s.normalize;
    }
    if (s.length > 40){
        s = s.shorten;
    }
    if (s.length > 40){
        s = s.shortenLastSegmentTemplating;
    }
    if (s.length > 40){
        s = s.collapse(40);
    }
    if (s.length > 40){
        s = "..."~s[$-37..$];
    }
    return s;
}

string format(LogEvent e){
    import std.string;
    string lvl = to!string(e.level).center(maxLevelNameLength, ' ');
    string path = e.loggerLocation.path;
    //if log happens in same aggregate place as logger was declared, use event path
    //if not, that means that logger was passed around to another piece of code
    //  in such case we should still show path of logger, since its the logger
    //  that is communicating to the reader of log
    if (e.eventLocation.path.startsWith(path))
        path = e.eventLocation.path;
    path = path.enforceLength(40);
    //todo enforce filename length in similar fashion; probably wrap these functions into struct that takes separator as field
    string filename = e.eventLocation.filename;
    string tid;
    return (filename~":"~to!string(e.eventLocation.line)).leftJustify(50)~" @ "~
    ( e.timestamp.empty ? 
        "N/A (compile-time)".center(25, ' ') : 
        e.timestamp.front().to!string.cutDown(25).leftJustify(25, ' ')
     ) ~ " ( " ~
     ( e.tid.empty ?
        "N/A".center(12, ' ') :
        e.tid.front().to!string["Tid(".length..$-")".length].center(12, ' ')
     ) ~
     " ) [ " ~ lvl ~ " ] " ~ 
     path.leftJustify(40, ' ')~" | "~
     to!string(e.message);
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
        //todo if dev is used, be angry? I mean, that method shouldn't be used in the final commit
        stdout.writeln(format(e));
        stdout.flush();
    }
}

struct LoggerConfig(_StaticLogSink){
    alias StaticLogSink = _StaticLogSink;
    bool figureOutEventAggregate=true;
}

enum DefaultConfig = LoggerConfig!(DefaultStaticSink)();

/**
 * if p="a.b!(c.d).e", then segments = ["a", "b!(c", "d)", "e"]
 * this foo turns that back to ["a", "b!(c.d)", "e"]
 */
string[] mergeBrokenSegments(string[] segs) {
    bool isBalanced(string s){
        import std.algorithm: canFind, sum;
        char[char] closingToOpen;
        closingToOpen[')'] = '(';
        closingToOpen[']'] = '[';
        int[char] counts;
        foreach (c; s){
            if (closingToOpen.values.canFind(c)){
                counts[c] += 1;
            } else if (c in closingToOpen){
                counts[closingToOpen[c]] -= 1;
            }
        }
        return counts.values.sum == 0;
    }
    string[] result;
    int i;
    while (i < segs.length){
        string current = segs[i];
        while (!isBalanced(current)){
            i += 1;
            if (i < segs.length){
                current ~= "."~segs[i];
            } else {
                if (!isBalanced(current)){
                    throw new Exception("Segments: "~to!string(segs)~" cannot be merged; the whole path doesn't seem to be balanced!");
                }
            }
        }
        i += 1;
        result ~= current;
    }
    return result;
}


/**
 * turn ["a", "b!(x)", "b"] (path "a.b!(x).b") into  ["a, "b!(x)"] ("a.b!(x)")
 * Assumes that input was already fixed with mergeBrokenSegments
 */
string[] normalizeSegments(string[] segs){
    import std.algorithm: startsWith;
    string[] result;
    int i; 
    while (i < segs.length-1){
        result ~= segs[i];
        if (segs[i].startsWith(segs[i+1]~"!")){
            i += 2;
        } else {
            i += 1;
        }
    }
    //todo there is probably some smarter condition to be used here
    if (result[$-1] != segs[$-1] && !result[$-1].startsWith(segs[$-1]))
        result ~= segs[$-1];
    return result;
}

string normalize(string p){
    import std.string;
    string[] segments= p.split(".");
       
    string[] merged = mergeBrokenSegments(segments);
    
    string[] normalized = normalizeSegments(merged);
    return normalized.join(".");
}

unittest {
    //todo move to other source set, test extensively
    static assert(mergeBrokenSegments(["a", "b", "c"]) == ["a", "b", "c"]);
    static assert(mergeBrokenSegments(["a", "b!(c", "d)", "e"]) == ["a", "b!(c.d)", "e"]);
    static assert(mergeBrokenSegments(["b!(c", "d)", "e"]) == ["b!(c.d)", "e"]);
    static assert(mergeBrokenSegments(["a", "b!(c", "d)"]) == ["a", "b!(c.d)"]);
    static assert(mergeBrokenSegments(["a", "b!(c", "d", "e)"]) == ["a", "b!(c.d.e)"]);
    
    static assert(normalizeSegments(["a", "b", "c"]) == ["a", "b", "c"]);
    static assert(normalizeSegments(["a!(x)", "a", "b", "c"]) == ["a!(x)", "b", "c"]);
    static assert(normalizeSegments(["a", "b!(x)", "b", "c"]) == ["a", "b!(x)", "c"]);
    static assert(normalizeSegments(["a", "b", "c!(x)", "c"]) == ["a", "b", "c!(x)"]);
    static assert(normalizeSegments(["a", "b", "c", "c!(x)"]) == ["a", "b", "c", "c!(x)"]);
    static assert(normalizeSegments(["a", "b", "c!(x)", "cd"]) == ["a", "b", "c!(x)", "cd"]);
    static assert(normalizeSegments(["a!(x)", "b!(x)", "b", "c"]) == ["a!(x)", "b!(x)", "c"]);
    static assert(normalizeSegments(["a!(x)", "a", "b!(x)", "b", "c"]) == ["a!(x)", "b!(x)", "c"]);
}

//todo params fromRight/fromLeft and maxLength
string[] shortenSegments(string[] segs){
    import std.string;
    import std.algorithm;
    string shortenSegment(string seg){
        string result = seg[0..1];
        if (seg.canFind("!")){
            result ~= "!(";
            string toAdd = seg.split("!")[1];
            while (toAdd.startsWith("!") || toAdd.startsWith("("))
                toAdd = toAdd[1..$];
            bool closeBrace = false;
            if (toAdd.startsWith("[")){
                closeBrace = true;
                result ~= "[";
                toAdd = toAdd[1..$];
                while (toAdd.startsWith("!") || toAdd.startsWith("("))
                    toAdd = toAdd[1..$];
            }
            result ~= toAdd[0];
            if (closeBrace)
                result ~= "...]";
            result ~= ")";
        }
        return result;
    }
    string[] result;
    foreach (s; segs[0..$-1]){
        result ~= shortenSegment(s);
    }
    result ~= segs[$-1];
    return result;
}

string shorten(string p){
    import std.string;
    string[] segments= p.split(".");
       
    string[] merged = mergeBrokenSegments(segments);
    
    string[] shortened = shortenSegments(merged);
    return shortened.join(".");
}

string shortenLastSegmentTemplating(string p){
    import std.string;
    import std.algorithm;
    string[] segments= p.split(".");
       
    string[] merged = mergeBrokenSegments(segments);
    string foo(string seg){
        string result = seg.split("!")[0];
        if (seg.canFind("!")){
            result ~= "!(";
            string toAdd = seg.split("!")[1];
            while (toAdd.startsWith("!") || toAdd.startsWith("("))
                toAdd = toAdd[1..$];
            bool closeBrace = false;
            if (toAdd.startsWith("[")){
                closeBrace = true;
                result ~= "[";
                toAdd = toAdd[1..$];
                while (toAdd.startsWith("!") || toAdd.startsWith("("))
                    toAdd = toAdd[1..$];
            }
            result ~= toAdd[0];
            if (closeBrace)
                result ~= "...]";
            result ~= ")";
        }
        return result;
    }
    string[] shortened = segments[0..$-1] ~ foo(segments[$-1]);
    return shortened.join(".");
}

unittest {
    //todo these can be static
    assert(shortenSegments(["abc", "def", "Ghi"]) == ["a", "d", "Ghi"]);
    assert(shortenSegments(["abc", "d!(ef)", "Ghi"]) == ["a", "d!(e)", "Ghi"]);
    assert(shortenSegments(["abc", "d!([ef])", "Ghi"]) == ["a", "d!([e...])", "Ghi"]);
    assert(shortenSegments(["abc", "def", "G!hi"]) == ["a", "d", "G!hi"]);
}

string collapse(string p, int maxLength){
    if (p.length <= maxLength){
        return p;
    }
    import std.string;
    import std.stdio;
    string[] segments= p.split(".");
       
    string[] merged = mergeBrokenSegments(segments);
    string[] pre;
    string[] post;
    immutable filler = "(...)";
    string result(){
        return (pre ~ (merged.empty ? [] : [filler]) ~ post).join(".");
    }
    bool fromRight = true;
    while (!merged.empty){
        if (fromRight){
            post = [ merged[$-1] ]~post;
            merged = merged[0..$-1];
            if (result().length > maxLength){
                merged ~= post[0];
                post = post[1..$];
                break;
            }
            fromRight = false;
        } else {
            pre ~= merged[0];
            merged = merged[1..$];
            if (result().length > maxLength){
                merged = pre[$-1] ~ merged;
                pre = pre[0..$-1];
                break;
            }
            fromRight = true;
        }
    }
    //if this couldn't produce a valid result, or the result was just (...), then 
    //just return original version and let the caller worry about it, we cannot 
    //collapse it any better
    if (result().length > maxLength || (pre.empty && post.empty))
        return p;
    return result();
}

unittest {
    assert(collapse("abc.def.ghi.jkl", 10) == "(...).jkl");
    assert(collapse("abc.def.ghi.jkl", 13) == "abc.(...).jkl");
    assert(collapse("abc.def.ghi.jkl", 15) == "abc.def.ghi.jkl");
    assert(collapse("abc.defgh!([e...]).Ghi", 15) == "abc.(...).Ghi");
}

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
    import optional: Optional;
    import std.datetime: SysTime;
    import std.concurrency: Tid;

    Level level;
    CodeLocation loggerLocation;
    CodeLocation eventLocation;
    string message;
    
    Optional!SysTime timestamp;
    Optional!Tid tid;
}

mixin template CreateLogger(alias config=DefaultConfig, string f=__FILE__, int l=__LINE__, string m=__MODULE__, string foo=__FUNCTION__,  string prettyFoo=__PRETTY_FUNCTION__){
    static if (__traits(compiles, typeof(this))){
        alias Here = typeof(this);
    } else {
        alias Here = ___Module___;
    }
    
    struct Logger {
        import std.traits: fullyQualifiedName;
        import std.meta: staticMap;
        import std.conv: to;
        import std.string: join;
        import std.algorithm: startsWith;
        import std.array: split;
        import std.datetime: Clock, SysTime;
        import std.concurrency: thisTid, Tid;
        import optional: Optional, no, some;
        
        LogSink logSink;
        
        this(LogSink logSink){
            this.logSink = logSink;
        }
        
        this(string f=__FILE__, int l=__LINE__, string m=__MODULE__, string foo=__FUNCTION__, string prettyFoo=__PRETTY_FUNCTION__)(){
            Warn!(f, l, m, foo, prettyFoo).Emit!("Creating logger with default sink! You're probably misconfigured!");
            this(new StdoutSink);
        }
        
        @property
        static CodeLocation location(){
            static if (is(Here == ___Module___)){
                return CodeLocation(f, l, m, "", foo, prettyFoo);
            } else {
                return CodeLocation(f, l, m, fullyQualifiedName!Here, foo, prettyFoo);
            }
        }
        
        static LogEvent event(Level level, string message, CodeLocation eventLocation, bool figureOutEventAggregate=true){
            if (figureOutEventAggregate) {
                
                if (location.moduleName == eventLocation.moduleName && 
                    location.aggregateName.length > 0 && eventLocation.functionName.length > 0 && 
                    eventLocation.functionName.startsWith(location.aggregateName)){
                        eventLocation.aggregateName = eventLocation.functionName.split(".")[0..$-1].join(".");
                }
            }
            if (__ctfe){
                return LogEvent(level, location, eventLocation, message, no!SysTime, no!Tid);
            } else {
                return LogEvent(level, location, eventLocation, message, Clock.currTime().some, thisTid.some);
            }
        }
        
        struct LogClosure(string f=__FILE__, int l=__LINE__, string m=__MODULE__, string foo=__FUNCTION__,  string prettyFoo=__PRETTY_FUNCTION__) {
            void Emit(Level level, T...)(){
                config.StaticLogSink.consume!(event(level, txt!T, CodeLocation(f, l, m, "", foo, prettyFoo), config.figureOutEventAggregate))();
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
                import std.conv;
                auto e = event(level, text!(T)(t), CodeLocation(f, l, m, "", foo, prettyFoo), config.figureOutEventAggregate);
                logSink.consume(e);
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
                Triple("Trace", "trace", "TRACE"),
                Triple("Dev", "dev", "DEVELOPMENT")
            ]){
            mixin LevelMixin!(t.s, t.r, t.m);
        }
    
        static string txt(T...)(){
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
                    return fold!(i+1, acc~asString!(T[i]))();
                } else {
                    return acc;
                }
            }
            return fold!(0, "")();
        }
        
        static string numberLines(string s, int l){
            import std.string: splitLines, leftJustify;
            import std.conv: to;
            
            string[] lines = s.splitLines();
            string result; 
            foreach (i, line; lines){
                result ~= to!string(l+i).leftJustify(4, ' ')~" |"~line~"\n"; //padding
            }
            return result;
        }
        
        static string indentLines(string s, string onLeft="\t"){
            import std.string: splitLines, leftJustify;
            import std.conv: to;
            
            string[] lines = s.splitLines();
            string result; 
            foreach (i, line; lines){
                result ~= onLeft~line~"\n";
            }
            return result;
        }
        
        struct LoggedClosure(string f=__FILE__, int l=__LINE__, string m=__MODULE__, string foo=__FUNCTION__,  string prettyFoo=__PRETTY_FUNCTION__) {
            //todo prefix/suffix should be customizable when obtaining this closure
            string value(string s)(){
                Dev!(f, l, m, foo, prettyFoo).Emit!("mixing in:\n"~indentLines(numberLines(s, l))~"--- END OF MIXIN ---")();
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
        
        mixin(Logger.logged.value!("enum CInnerEnum;"));
        
        static void foo(string bastard="you"){
            mixin CreateLogger!();
            Logger.Info.Emit!"HEY";
            log.info.emit("hey "~bastard);
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
    Logger.Info.Emit!("A1 ", "A2 ", "A3 ", "A4");
    Logger.Info.Emit!("Foo ")();
    Logger(new StdoutSink).info().emit("howdy");
    C.Logger.Debug.Emit!"Something";
    C.foo();
    C.log.debug_.emit("hey");
}
unittest {
    new C().bar("");
    C.foo("world");
    I.Logger.Info.Emit!"XXX";
    baz();
}

unittest{
    testFoo();
}
