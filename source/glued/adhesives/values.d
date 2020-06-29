module glued.adhesives.values;

import std.algorithm;
import std.range;
import std.traits;
import std.variant;

import glued.logging;

import dejector;
import optional;

template isValue(T) {};

interface ValueSource
{
    Optional!T findValue(T)(string query, string path)
        if (isValue!T);
    
    final Optional!T findValue(T)(string path)
        if (isValue!T)
    {
        //todo consider using queryString from dejector? or finally merge dejector fork here
        return findValue(fullyQualifiedName!(T), path).map!(x => x.get!(T)).toOptional;
    }
}

class ValueRegistrar
{
    mixin CreateLogger;
    private Logger log;
    private Dejector injector;
    private ValueSource[] sources;
    
    this(Dejector injector, LogSink sink){
        log = Logger(sink);
        this.injector = injector;
    }
    
    void register(ValueSource source)
    {
        sources ~= source;
    }
    
    Optional!T resolveValue(T)(string path)
    {
        return sources.map!(s => s.findValue!(T)(path)).joiner().take(1).toOptional;
    }
}
