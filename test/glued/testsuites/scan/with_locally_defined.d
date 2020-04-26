module glued.testsuites.scan.with_locally_defined;

import std.stdio;
import std.traits;
import std.algorithm.searching;

import glued.scan;
import glued.mirror;
import glued.set;
import glued.testutils;

import glued.testsuites.scan.common;
    
mixin unrollLoopThrough!([at("ex2.sub1"), at("ex2.sub2")], GatherPairsSetup!"gatherPairs", GatherPairsConsumer, NoOp, GatherPairsTeardown);

unittest {
    auto found = gatherPairs();
    assert(found == Set!Pair.of([Pair("ex2.sub1.m1", "C"), Pair("ex2.sub2.m2", "I")]));
}
