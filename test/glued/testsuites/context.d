module glued.testsuites.context;

import std.stdio;
import std.traits;

import glued.context;
import glued.scannable;
import glued.logging;
import glued.collections;
import glued.utils;

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
    import glued.collections.reference;
    Reference!(Object[]) result = d.injector.get!(Reference!(I1[]), Reference!(Object[]))();
    I1[] impls = result.castDown!(I1[])();
    assert(impls.length == 1);
    assert(impls[0].isInstance!C4);

    Reference!(Object[]) result2 = d.injector.get!(Reference!(I2[]), Reference!(Object[]))();
    I2[] impls2 = result2.castDown!(I2[])();
    assert(impls2.length == 3);
    assert(impls2[0].isInstance!C3);
    assert(impls2[1].isInstance!C4);
    assert(impls2[2].isInstance!C5);
    //for I2:
    //["ex3.mod.C2", "ex3.mod.C3", "ex3.mod.C4", "ex3.mod.C5"] //without C2 because it is Tracked and not a Component, hence is not instantiable
    writeln("autobinding interfaces passed (very early stage)");
}
