module glued.testsuites.scan.with_tracking_by_context;

import std.stdio;
import std.traits;
import std.algorithm.searching;

import glued.scan;
import glued.mirror;
import glued.testutils;

import glued.context;

enum TrackByBackboneSetup = "void track(BackboneContext context) { import glued.stereotypes; ";
enum TrackByBackboneConsumer(string m, string n) = "context.track!(\""~m~"\", \""~n~"\")();";
enum TrackByBackboneTeardown = "}";
    
mixin scan!([at("ex1")], TrackByBackboneSetup, TrackByBackboneConsumer, TrackByBackboneTeardown);

unittest {
    //this tests scanning method in the same module as usage
    import glued.context;
    
    BackboneContext ctx = new BackboneContext();
    track(ctx);
    
    template aggrPred(string m, string n) {
        alias aggrPred = (x) => x.moduleName == m && x.aggregate.identifier == n;
    }
    
    assert(ctx.tracked.find!(aggrPred!("ex1.scan_aggregates", "X")));
    assert(ctx.tracked.find!(aggrPred!("ex1.scan_aggregates", "Y")));
    assert(ctx.tracked.find!(aggrPred!("ex1.scan_aggregates", "Z")));
    assert(ctx.tracked.find!(aggrPred!("ex1.enum_", "NonTrackedBecauseEnum")));
    assert(ctx.tracked.find!(aggrPred!("ex1.scan_aggregates", "NonTrackedStruct")));
}

