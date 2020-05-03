module apps.app1.impl;

import std.algorithm;
import std.array;

import glued.logging;
import glued.application;
import glued.adhesives;
import glued.set;

import apps.app1.deps;
import apps.app1.stereotypes;

@Component
class TestData {
    bool touched;
    int[] iFoos;
    string direct;
    bool indirect;
}

@App1Component
class App1Action: ApplicationAction {
    @Autowire
    InterfaceResolver resolver;
    
    @Autowire
    DirectlyInjected directly;
    
    @Autowire
    IndirectlyInjected indirectly; //fixme this is null
    
    @Autowire
    TestData data;

    void execute(){
        data.touched = true;
        auto impls = resolver.getImplementations!I;
        auto mapped = impls.map!(x => x.foo());
        import std.traits;
        auto arr = mapped.array;
        data.iFoos = arr;
        data.direct = directly.bar();
        data.indirect = indirectly.baz();
    }
}
