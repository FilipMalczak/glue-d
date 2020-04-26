module glued.testsuites.bundles;

import std.algorithm;

import glued.scan;
import glued.scannable;

import glued.set;

unittest {
    //todo: move to scan/deep_with_bundles
    Set!string collected;
    enum perBundle(string s) = "collected.add(\""~s~"\");";
    mixin unrollLoopThrough!([Scannable("bundles")], "void doScan() { ", NoOp, perBundle, "}");
    
    doScan();
    assert(collected == Set!string.of(["bundles.content.onlysubpkgs._test_bundle", "bundles.content.onlysubpkgs.mixed._test_bundle", "bundles.content.onlysubpkgs.mixed.empty._test_bundle", "bundles.content.onlysubpkgs.onlysubmods._test_bundle"]));
}
