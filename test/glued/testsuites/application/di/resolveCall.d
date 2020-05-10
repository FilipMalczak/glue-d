module glued.testsuites.application.di.resolveCall;

import foo.api;
import foo.operators;

import glued.application;
import glued.logging;

import glued.testsuites.runtime: compareResults;

class FooForFunction: FooWithExpected
{
    Operator power;
    
    Operator multiply;
    
    Add add;

    this(Operator power, Operator multiply, Add add)
    {
        this.power = power;
        this.multiply = multiply;
        this.add = add;
    }

    int foo(int x)
    {
        return add.apply(
            add.apply(
                power.apply(x, 2),
                multiply.apply(4, x)
            ),
            1
        );
    }
    
    int expected(int x)
    {
        return x*x + 4*x + 1;
    }
}

@OnParameter!(0, Autowire!Power)
auto freeFunctionByIdx(Operator power, Operator multiply, Add add)
{
    return new FooForFunction(power, multiply, add);
}

unittest {
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    import foo.api;
    auto impl = resolveCall!(freeFunctionByIdx)(r.injector, &freeFunctionByIdx);
    assert(impl !is null);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("resolveCall with free function and params by idx passed");
}
