module glued.testsuites.scan.with_externally_defined;

import std.stdio;
import std.traits;

import std.algorithm.searching;

import glued.mirror;
import glued.testutils;

import glued.testsuites.scan.scanner_def;

import ex1.scan_aggregates;

unittest {
    //this tests scanning method in different module than its usage
    Pair[] found = gatherPairs();
    assert(count(found, toPair!X) > 0);
    assert(count(found, toPair!Ster) > 0);
    assert(count(found, toPair!Y) > 0);
    assert(count(found, toPair!Z) > 0);
    //if I use templating with toPair!NotTrackedBecauseEnum, there will be a compilation error
    assert(count(found, Pair("ex1.enum_", "NonTrackedBecauseEnum")) > 0);
    assert(count(found, toPair!NonTrackedStruct) > 0);
}

