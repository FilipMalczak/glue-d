module glued.testsuites.bundles;

import std.algorithm;

import glued.codescan.unrollscan;

import glued.set;

import glued.adhesives.bundles;

unittest {
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
