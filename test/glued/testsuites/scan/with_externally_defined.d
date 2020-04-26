module glued.testsuites.scan.with_externally_defined;

import std.stdio;
import std.traits;

import std.algorithm.searching;

import glued.mirror;
import glued.set;
import glued.testutils;

import glued.testsuites.scan.scanner_def;

import ex1.scan_aggregates;

unittest {
    //this tests scanning method in different module than its usage
    auto found = gatherPairs();
    assert(found == Set!Pair.of([toPair!X, toPair!Ster, toPair!Y, toPair!Z, toPair!NonTrackedStruct, Pair("ex1.enum_", "NonTrackedBecauseEnumInOtherModule"), Pair("ex1.enum_", "E")]));
    //if I use templating with toPair!NotTrackedBecauseEnum, there will be a compilation error
}

