module glued.testsuites.bundles;

import glued.scan;
import glued.scannable;

unittest {
    string[] collected;
    enum perBundle(string s) = "collected ~= \""~s~"\";";
    mixin unrollLoopThrough!([Scannable("bundles")], "void doScan() { ", NoOp, perBundle, "}");
    
    doScan();
    
    assert(collected == ["bundles.content.onlysubpkgs._test_bundle", "bundles.content.onlysubpkgs.onlysubmods._test_bundle", "bundles.content.onlysubpkgs.mixed._test_bundle", "bundles.content.onlysubpkgs.mixed.empty._test_bundle"]);
}
