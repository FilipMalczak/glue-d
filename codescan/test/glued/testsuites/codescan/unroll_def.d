module glued.testsuites.codescan.unroll_def;

import std.traits;

import glued.utils;

import glued.testutils;

import glued.codescan.unrollscan;

import glued.testsuites.codescan.common;

//todo bundles, scannables
mixin unrollLoopThrough!(at("ex1", "", "scantest"), GatherPairsSetup!("gatherPairs"), GatherPairsConsumer, NoOp, GatherPairsTeardown);
