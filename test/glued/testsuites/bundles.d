module glued.testsuites.bundles;

import std.algorithm;

import glued.scan;
import glued.scannable;

import glued.set;

import glued.context.bundles;

unittest {
    //todo: move to scan/deep_with_bundles
    Set!string collected;
    enum perBundle(string s) = "collected.add(\""~s~"\");";
    mixin unrollLoopThrough!([Scannable("bundles")], "void doScan() { ", NoOp, perBundle, "}");
    
    doScan();
    assert(collected == Set!string.of(["bundles.content.onlysubpkgs._test_bundle", "bundles.content.onlysubpkgs.mixed._test_bundle", "bundles.content.onlysubpkgs.mixed.empty._test_bundle", "bundles.content.onlysubpkgs.onlysubmods._test_bundle"]));
}

unittest {
    import std.stdio;
    writeln(Set!string.of(
            new GluedBundle!("bundles.content.onlysubpkgs._test_bundle")()
                .ls()
                .map!(x => x.url) 
        ));
    assert(
        Set!string.of(
            new GluedBundle!("bundles.content.onlysubpkgs._test_bundle")()
                .ls()
                .map!(x => x.url) 
        )
        == 
        //todo hardcoded unix separator
        Set!string.of([
            "glue://bundles/content/onlysubpkgs/f1.txt", 
            "glue://bundles/content/onlysubpkgs/f2.txt"
        ])
    );
}
