module glued.testsuites.singleton;

import glued.singleton;

class TestContext {
    string val;
    
    mixin HasSingleton;
}

unittest {
    assert(Root!TestContext.get().value.val == "");
    assert(TestContext.get().val == "");
    Root!TestContext.get().value.val = "abc";
    assert(Root!TestContext.get().value.val == "abc");
    assert(TestContext.get().val == "abc");
    TestContext.get().val = "def";
    assert(Root!TestContext.get().value.val == "def");
    assert(TestContext.get().val == "def");
}
