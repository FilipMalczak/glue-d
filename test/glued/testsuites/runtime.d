module glued.testsuites.runtime;

import std.algorithm;
import std.meta;

import glued.application;
import glued.logging;
import glued.set;
import glued.utils;

import glued.testutils;

import dejector; //fixme only for queryString; same old story -.-'

unittest 
{
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto runtime = new GluedRuntime!(at("apps.app1"))();
    runtime.start(["a"]);
    import apps.app1.impl: TestData;
    TestData data = runtime.injector.get!TestData;
    assert(data.touched);
    runtime.shutDown();
    assert(runtime.injector is null);
    log.info.emit("Runtime with apps.app1 passed");
}


unittest 
{
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("ex1"))();
    r.start();

    import ex1.scan_aggregates: Z;
    Z inst = r.injector.get!Z;
    assert(inst !is null);
    log.info.emit("runtime with ex1 passed");
}

unittest 
{
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    import foo.api;
    auto impl = r.injector.get!FooByField;
    assert(impl !is null);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("runtime with foo/byField passed");
}

unittest 
{
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    import foo.api;
    auto impl = r.injector.get!FooByConstructor;
    assert(impl !is null);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("runtime with foo/byConstructor passed");
}

unittest 
{
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    import foo.api;
    auto impl = r.injector.get!FooByProperty;
    assert(impl !is null);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("runtime with foo/byProperty passed");
}

unittest 
{
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    import foo.api;
    auto impl = r.injector.get!MixedFoo;
    assert(impl !is null);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("runtime with foo/mixed passed");
}

unittest 
{
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("ex3"))();
    r.start();
    
    import ex3.mod;
    InterfaceResolver resolver = r.injector.get!InterfaceResolver;
    
    auto objects = Set!Object.of(resolver.getImplementations(queryString!I1));
    auto impls = Set!I1.of(resolver.getImplementations!I1);
    
    assert(objects.asSetOf!I1 == impls);
    assert(objects == impls.asSetOf!Object);
    
    assert(impls.asRange.canFind!(x => isInstance!(C4)(x)));

    auto objects2 = Set!Object.of(resolver.getImplementations(queryString!I2));
    auto impls2 = Set!I2.of(resolver.getImplementations!I2);
    
    assert(objects2.asSetOf!I2 == impls2);
    assert(objects2 == impls2.asSetOf!Object);
    
    //without C2 because it is Tracked and not a Component, hence is not instantiable
    static foreach (t; AliasSeq!(C3, C4, C5))
    {
        assert(impls2.asRange.canFind!(x => isInstance!(t)(x)));
    }
    
    assert(impls2.length == 3);
    
    log.info.emit("autobinding implementations passed");
}
////todo autobinding sole impl

