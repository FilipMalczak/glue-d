module apps.app1.deps;

import apps.app1.stereotypes;

interface I {
    int foo();
}

@App1Component
class Impl1: I {
    int foo(){return 1;}
}

@App1Component
class Impl2: I {
    int foo(){return 2;}
}

@App1Component
class DirectlyInjected {
    string bar() { return "yep"; }
}

interface IndirectlyInjected {
    bool baz();
}

@App1Component
class IndirectlyInjectedImpl: IndirectlyInjected {
    bool baz() { return false; }
}
