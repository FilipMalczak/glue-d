module glued.testsuites.context;

import std.stdio;
import std.traits;

import glued.context;
import glued.scannable;

unittest {
    auto d = new DefaultGluedContext;
    
    d.scan!([at("ex1")])();
    
    import ex1.scan_aggregates: Z;
    Z inst = d.injector.get!Z;
    assert(inst !is null);
    writeln("context with ex1 passed");
}

unittest {
    auto d = new DefaultGluedContext;
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
    auto d = new DefaultGluedContext;
    d.scan!([at("foo")])();
    writeln("scan finished");
    import foo.api;
    Api api = d.injector.get!Api;
    assert(api !is null);
    writeln(__LINE__, " ", api);
    writeln(__LINE__, " ", api.power, "@", &(api.power));
    writeln(__LINE__, " ", api.multiply, "@", &(api.multiply));
    writeln(__LINE__, " ", api.add, "@", &(api.add));
    int expected(int x){
        return x*x + 5*x + 3;
    }
    
    assert(api.foo(0) == expected(0));
    assert(api.foo(1) == expected(1));
    assert(api.foo(2) == expected(2));
    assert(api.foo(5) == expected(5));
    //todo randomized tests?
}
