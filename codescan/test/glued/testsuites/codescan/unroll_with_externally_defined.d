module glued.testsuites.codescan.unroll_with_externally_defined;

import std.stdio;
import std.traits;

import std.algorithm.searching;

import glued.mirror;
import glued.set;
import glued.testutils;

import glued.testsuites.codescan.unroll_def;

import ex1.scan_aggregates;

//todo same test, but without importing these types here, but rather manually constructing Pair(...)
unittest 
{
    auto found = gatherPairs();
    assert(found == Set!Pair.of([
        toPair!C, 
        toPair!I, 
        toPair!C2, 
        toPair!Struct,
        toPair!JustEnum,
        toPair!StringEnum
    ]));
}

