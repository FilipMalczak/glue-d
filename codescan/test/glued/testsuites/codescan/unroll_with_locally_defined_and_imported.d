module glued.testsuites.codescan.unroll_with_locally_defined_and_imported;

import std.traits;
import std.algorithm.searching;

import glued.mirror;
import glued.set;
import glued.testutils;

import glued.codescan.unrollscan;

import glued.testsuites.codescan.common;

import ex2.sub1.m1;
import ex2.sub2.m2;

//todo bundles
mixin unrollLoopThrough!(at("ex2", "", "scantest"), GatherPairsSetup!"gatherPairs", GatherPairsConsumer, NoOp, GatherPairsTeardown);

unittest 
{
    auto found = gatherPairs();
    assert(found == Set!Pair.of([toPair!C, toPair!I]));
}
