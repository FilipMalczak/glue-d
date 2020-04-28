module glued.testsuites.application;

import glued.application;

unittest {
    auto runtime = new GluedRuntime!(at("apps.app1"))();
    runtime.start(["a"]);
    import apps.app1.impl: TestData;
    TestData data = runtime.currentContext.get!TestData;
    assert(data.touched);
    runtime.shutDown();
    assert(runtime.currentContext is null);
}
