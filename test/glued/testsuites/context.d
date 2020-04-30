module glued.testsuites.context;

import std.stdio;
import std.traits;
import std.meta;
import std.algorithm;

import glued.context;
import glued.scannable;
import glued.logging;
import glued.utils;

import dejector; //only for queryString - this must stop
import glued.set;

unittest {
    auto d = new DefaultGluedContext(new StdoutSink);

    d.scan!([at("ex1")])();

    import ex1.scan_aggregates: Z;
    Z inst = d.injector.get!Z;
    assert(inst !is null);
    writeln("context with ex1 passed");
}

unittest {
    auto d = new DefaultGluedContext(new StdoutSink);
    d.scan!([at("foo")])();
    writeln("scan finished");
    import foo.api;
    Api api = d.injector.get!Api;
    assert(api !is null);
    int expected(int x){
        return x*x + 5*x + 3;
    }

    assert(api.foo(0) == expected(0));
    assert(api.foo(1) == expected(1));
    assert(api.foo(2) == expected(2));
    assert(api.foo(5) == expected(5));
    writeln("context with foo passed");
    //todo randomized tests?
}

unittest {
    import std.stdio;
    auto d = new DefaultGluedContext(new StdoutSink);
    d.scan!([at("foo")])();
    writeln("scan finished");
    import foo.api;
    Api api = d.injector.get!Api;
    assert(api !is null);
    int expected(int x){
        return x*x + 5*x + 3;
    }
    assert(api.foo(0) == expected(0));
    assert(api.foo(1) == expected(1));
    assert(api.foo(2) == expected(2));
    assert(api.foo(5) == expected(5));
    writeln("Api and operators passed");
    //todo randomized tests?
}

unittest {
    import std.stdio;
    auto d = new DefaultGluedContext(new StdoutSink);
    d.scan!([at("ex3")])();
    writeln("scan finished");
    import ex3.mod;
    InterfaceResolver resolver = d.injector.get!InterfaceResolver;
    auto objects = Set!Object.of(resolver.getImplementations(queryString!I1));
    auto impls = Set!I1.of(resolver.getImplementations!I1);
    assert(objects.asSetOf!I1 == impls);
    assert(objects == impls.asSetOf!Object);
    assert(impls.asRange.canFind!(x => isInstance!(C4)(x)));

    auto objects2 = Set!Object.of(resolver.getImplementations(queryString!I2));
    auto impls2 = Set!I2.of(resolver.getImplementations!I2);
    assert(objects2.asSetOf!I2 == impls2);
    assert(objects2 == impls2.asSetOf!Object);
    static foreach (t; AliasSeq!(C3, C4, C5)){
        assert(impls2.asRange.canFind!(x => isInstance!(t)(x)));
    }
    //for I2:
    //["ex3.mod.C2", "ex3.mod.C3", "ex3.mod.C4", "ex3.mod.C5"] //without C2 because it is Tracked and not a Component, hence is not instantiable
    writeln("autobinding all implementations passed");
}
//todo autobinding sole impl
