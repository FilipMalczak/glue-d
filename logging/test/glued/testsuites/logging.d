module glued.teststuites.logging;

import glued.logging;

unittest {
    static assert(mergeBrokenSegments(["a", "b", "c"]) == ["a", "b", "c"]);
    static assert(mergeBrokenSegments(["a", "b!(c", "d)", "e"]) == ["a", "b!(c.d)", "e"]);
    static assert(mergeBrokenSegments(["b!(c", "d)", "e"]) == ["b!(c.d)", "e"]);
    static assert(mergeBrokenSegments(["a", "b!(c", "d)"]) == ["a", "b!(c.d)"]);
    static assert(mergeBrokenSegments(["a", "b!(c", "d", "e)"]) == ["a", "b!(c.d.e)"]);
}

unittest {
    static assert(normalizeSegments(["a", "b", "c"]) == ["a", "b", "c"]);
    static assert(normalizeSegments(["a!(x)", "a", "b", "c"]) == ["a!(x)", "b", "c"]);
    static assert(normalizeSegments(["a", "b!(x)", "b", "c"]) == ["a", "b!(x)", "c"]);
    static assert(normalizeSegments(["a", "b", "c!(x)", "c"]) == ["a", "b", "c!(x)"]);
    static assert(normalizeSegments(["a", "b", "c", "c!(x)"]) == ["a", "b", "c", "c!(x)"]);
    static assert(normalizeSegments(["a", "b", "c!(x)", "cd"]) == ["a", "b", "c!(x)", "cd"]);
    static assert(normalizeSegments(["a!(x)", "b!(x)", "b", "c"]) == ["a!(x)", "b!(x)", "c"]);
    static assert(normalizeSegments(["a!(x)", "a", "b!(x)", "b", "c"]) == ["a!(x)", "b!(x)", "c"]);
}


unittest {
    //todo these can be static
    assert(shortenSegments(["abc", "def", "Ghi"]) == ["a", "d", "Ghi"]);
    assert(shortenSegments(["abc", "d!(ef)", "Ghi"]) == ["a", "d!(e)", "Ghi"]);
    assert(shortenSegments(["abc", "d!([ef])", "Ghi"]) == ["a", "d!([e...])", "Ghi"]);
    assert(shortenSegments(["abc", "def", "G!hi"]) == ["a", "d", "G!hi"]);
}


unittest {
    assert(collapse("abc.def.ghi.jkl", 10) == "(...).jkl");
    assert(collapse("abc.def.ghi.jkl", 13) == "abc.(...).jkl");
    assert(collapse("abc.def.ghi.jkl", 15) == "abc.def.ghi.jkl");
    assert(collapse("abc.defgh!([e...]).Ghi", 15) == "abc.(...).Ghi");
}


mixin CreateLogger!();

class C {
    mixin CreateLogger!();

    static auto log = Logger(new StdoutSink);
    
    mixin(Logger.logged.value!("enum CInnerEnum;"));
    
    static void foo(string bastard="you"){
        mixin CreateLogger!();
        Logger.Info.Emit!"HEY";
        log.info.emit("hey "~bastard);
    }
    
    void bar(string a){
        mixin CreateLogger!();
        
        Logger.Info.Emit!"HO";
    }
}

interface I {
    mixin CreateLogger!();
}

void baz(){
    mixin CreateLogger!();
    auto log = Logger(new StdoutSink);
    log.Debug.Emit!"VAZ";
}

void testFoo(){
    LogSink logSink = new StdoutSink;
    mixin CreateLogger!();
    Logger.Info.Emit!"XYZ";
    Logger(new StdoutSink).info().emit("123");
}

//todo it all works on StdoutSink; test it on some event collector, analyze events post mortem
//fixme but how do I do that with build logs?
unittest {
    Logger.Info.Emit!("A1 ", "A2 ", "A3 ", "A4");
    Logger.Info.Emit!("Foo ")();
    Logger(new StdoutSink).info().emit("howdy");
    C.Logger.Debug.Emit!"Something";
    C.foo();
    C.log.debug_.emit("hey");
}
unittest {
    new C().bar("");
    C.foo("world");
    I.Logger.Info.Emit!"XXX";
    baz();
}

unittest{
    testFoo();
}
