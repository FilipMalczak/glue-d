module glued.testsuites.context;

import std.traits;

import glued.context;
import glued.scannable;

unittest {
    auto d = new shared GluedContext;
    
    d.scan!([at("ex1")])();
    
    import ex1.scan_aggregates: Z;
    Z inst = d.internalDiContext.resolve!Z;
    assert(inst !is null);
}

unittest {
    import std.stdio;
    auto d = new shared GluedContext;
    d.scan!([at("foo")])();
    writeln("scan finished");
    import foo.api;
    Api api = d.internalDiContext.resolve!Api;
    
//    int expected(int x){
//        return x*x + 5*x + 3;
//    }
//    
//    assert(api.foo(0) == expected(0));
//    assert(api.foo(1) == expected(1));
//    assert(api.foo(2) == expected(2));
//    assert(api.foo(5) == expected(5));
    //todo randomized tests?
}
