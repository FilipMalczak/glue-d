module glued.testsuites.scan.scanner_def;

import glued.scan;
import glued.utils;

import glued.testutils;
import std.traits;

import glued.testsuites.scan.common;

mixin unrollLoopThrough!(at("ex1"), GatherPairsSetup!("gatherPairs"), GatherPairsConsumer, NoOp, GatherPairsTeardown);
