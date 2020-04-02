module glued.testsuites.scan.with_locally_defined;

import std.stdio;
import std.traits;
import std.algorithm.searching;

import glued.scan;
import glued.mirror;
import glued.testutils;

import glued.testsuites.scan.common;
    
mixin scan!([at("ex2.sub1"), at("ex2.sub2")], GatherPairsSetup!"gatherPairs", GatherPairsConsumer, GatherPairsTeardown);

unittest {
    Pair[] found = gatherPairs();
    assert(found.count(Pair("ex2.sub1.m1", "C")));
    assert(found.count(Pair("ex2.sub2.m2", "I")));
}
