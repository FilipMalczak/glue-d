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
auto freeFunctionByFirstIdx(Operator power, Operator multiply, Add add)
{
    return new FooForFunction(power, multiply, add);
}

unittest {
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    auto impl = resolveCall!(freeFunctionByFirstIdx)(r.injector, &freeFunctionByFirstIdx);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("resolveCall with free function and params by first idx passed");
}

@OnParameter!(1, Autowire!Power)
auto freeFunctionByMiddleIdx(Operator multiply, Operator power, Add add)
{
    return new FooForFunction(power, multiply, add);
}

unittest {
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    auto impl = resolveCall!(freeFunctionByMiddleIdx)(r.injector, &freeFunctionByMiddleIdx);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("resolveCall with free function and params by middle idx passed");
}

@OnParameter!(2, Autowire!Power)
auto freeFunctionByLastIdx(Operator multiply, Add add, Operator power)
{
    return new FooForFunction(power, multiply, add);
}

unittest {
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();

    auto impl = resolveCall!(freeFunctionByLastIdx)(r.injector, &freeFunctionByLastIdx);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("resolveCall with free function and params by last idx passed");
}


@OnParameter!("power", Autowire!Power)
auto freeFunctionByFirstName(Operator power, Operator multiply, Add add)
{
    return new FooForFunction(power, multiply, add);
}

unittest {
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    auto impl = resolveCall!(freeFunctionByFirstName)(r.injector, &freeFunctionByFirstName);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("resolveCall with free function and params by first name passed");
}

@OnParameter!("power", Autowire!Power)
auto freeFunctionByMiddleName(Operator multiply, Operator power, Add add)
{
    return new FooForFunction(power, multiply, add);
}

unittest {
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    auto impl = resolveCall!(freeFunctionByMiddleName)(r.injector, &freeFunctionByMiddleName);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("resolveCall with free function and params by middle name passed");
}

@OnParameter!("power", Autowire!Power)
auto freeFunctionByLastName(Operator multiply, Add add, Operator power)
{
    return new FooForFunction(power, multiply, add);
}

unittest {
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    auto impl = resolveCall!(freeFunctionByLastName)(r.injector, &freeFunctionByLastName);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("resolveCall with free function and params by last name passed");
}

class ConfigLike {
    @OnParameter!(0, Autowire!Power)
    static auto staticMethodByFirstIdx(Operator power, Operator multiply, Add add)
    {
        return new FooForFunction(power, multiply, add);
    }
    
    @OnParameter!(0, Autowire!Power)
    auto instanceMethodByFirstIdx(Operator power, Operator multiply, Add add)
    {
        return new FooForFunction(power, multiply, add);
    }
    
    @OnParameter!("power", Autowire!Power)
    static auto staticMethodByFirstName(Operator power, Operator multiply, Add add)
    {
        return new FooForFunction(power, multiply, add);
    }
    
    @OnParameter!("power", Autowire!Power)
    auto instanceMethodByFirstName(Operator power, Operator multiply, Add add)
    {
        return new FooForFunction(power, multiply, add);
    }
    
    @OnParameter!(1, Autowire!Power)
    static auto staticMethodByMiddleIdx(Operator multiply, Operator power, Add add)
    {
        return new FooForFunction(power, multiply, add);
    }
    
    @OnParameter!(1, Autowire!Power)
    auto instanceMethodByMiddleIdx(Operator multiply, Operator power, Add add)
    {
        return new FooForFunction(power, multiply, add);
    }
    
    @OnParameter!("power", Autowire!Power)
    static auto staticMethodByMiddleName(Operator multiply, Operator power, Add add)
    {
        return new FooForFunction(power, multiply, add);
    }
    
    @OnParameter!("power", Autowire!Power)
    auto instanceMethodByMiddleName(Operator multiply, Operator power, Add add)
    {
        return new FooForFunction(power, multiply, add);
    }
    
    @OnParameter!(2, Autowire!Power)
    static auto staticMethodByLastIdx(Add add, Operator multiply, Operator power)
    {
        return new FooForFunction(power, multiply, add);
    }
    
    @OnParameter!(2, Autowire!Power)
    auto instanceMethodByLastIdx(Add add, Operator multiply, Operator power)
    {
        return new FooForFunction(power, multiply, add);
    }
    
    @OnParameter!("power", Autowire!Power)
    static auto staticMethodByLastName(Add add, Operator multiply, Operator power)
    {
        return new FooForFunction(power, multiply, add);
    }
    
    @OnParameter!("power", Autowire!Power)
    auto instanceMethodByLastName(Add add, Operator multiply, Operator power)
    {
        return new FooForFunction(power, multiply, add);
    }
}

//todo it would be good to test what happens when there are overloads of the method - both using __traits(getOverloads, X, "y") and X.y

unittest {
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    auto impl = resolveCall!(ConfigLike.staticMethodByFirstIdx)(r.injector, &ConfigLike.staticMethodByFirstIdx);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("resolveCall with static method and params by first idx passed");
}


unittest {
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    ConfigLike instance = new ConfigLike;
    auto impl = resolveCall!(ConfigLike.instanceMethodByFirstIdx)(r.injector, &instance.instanceMethodByFirstIdx);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("resolveCall with instance method and params by first idx passed");
}

unittest {
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    auto impl = resolveCall!(ConfigLike.staticMethodByFirstName)(r.injector, &ConfigLike.staticMethodByFirstName);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("resolveCall with static method and params by first name passed");
}


unittest {
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    ConfigLike instance = new ConfigLike;
    auto impl = resolveCall!(ConfigLike.instanceMethodByFirstName)(r.injector, &instance.instanceMethodByFirstName);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("resolveCall with instance method and params by first name passed");
}


unittest {
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    auto impl = resolveCall!(ConfigLike.staticMethodByMiddleIdx)(r.injector, &ConfigLike.staticMethodByMiddleIdx);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("resolveCall with static method and params by middle idx passed");
}


unittest {
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    ConfigLike instance = new ConfigLike;
    auto impl = resolveCall!(ConfigLike.instanceMethodByMiddleIdx)(r.injector, &instance.instanceMethodByMiddleIdx);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("resolveCall with instance method and params by middle idx passed");
}

unittest {
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    auto impl = resolveCall!(ConfigLike.staticMethodByMiddleName)(r.injector, &ConfigLike.staticMethodByMiddleName);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("resolveCall with static method and params by middle name passed");
}


unittest {
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    ConfigLike instance = new ConfigLike;
    auto impl = resolveCall!(ConfigLike.instanceMethodByMiddleName)(r.injector, &instance.instanceMethodByMiddleName);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("resolveCall with instance method and params by middle name passed");
}



unittest {
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    auto impl = resolveCall!(ConfigLike.staticMethodByLastIdx)(r.injector, &ConfigLike.staticMethodByLastIdx);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("resolveCall with static method and params by last idx passed");
}


unittest {
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    ConfigLike instance = new ConfigLike;
    auto impl = resolveCall!(ConfigLike.instanceMethodByLastIdx)(r.injector, &instance.instanceMethodByLastIdx);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("resolveCall with instance method and params by last idx passed");
}

unittest {
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    auto impl = resolveCall!(ConfigLike.staticMethodByLastName)(r.injector, &ConfigLike.staticMethodByLastName);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("resolveCall with static method and params by last name passed");
}


unittest {
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    auto r = new GluedRuntime!(at("foo"))();
    r.start();
    
    ConfigLike instance = new ConfigLike;
    auto impl = resolveCall!(ConfigLike.instanceMethodByLastName)(r.injector, &instance.instanceMethodByLastName);

    compareResults(impl, [0, 1, 2, 5], 5);
    log.info.emit("resolveCall with instance method and params by last name passed");
}
