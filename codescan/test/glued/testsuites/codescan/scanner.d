module glued.testsuites.codescan.scanner;

import std.conv;
import std.traits;

import glued.logging;
import glued.set;

import glued.codescan.scanner;

enum CollectionEvent { SCANNABLE, TYPE, BUNDLE, FREEZE }

//if we customize indexer config, make sure to reflect it here
enum toScan(string s) = at(s, "", "scantest");

struct ColletionResult {
    CollectionEvent event;
    string pointer;
}

class AllColectionResults {
    ColletionResult[] results; 
    
    void add(CollectionEvent e, string s){
        results ~= ColletionResult(e, s);
    }
}

class AllCollectingListener: Listener!(AllColectionResults) 
{
    AllColectionResults results = null;

    void init(AllColectionResults results){
        this.results = results;
    }

    void onScannable(alias scannable)() if (isScannable!scannable) {
        results.add(CollectionEvent.SCANNABLE, to!string(scannable));
    }
    
    void onType(T)(){
        results.add(CollectionEvent.TYPE, fullyQualifiedName!(T));
    }
    
    void onBundleModule(string modName)(){
        results.add(CollectionEvent.BUNDLE, modName);
    }
    
    void onScannerFreeze(){
        results.add(CollectionEvent.FREEZE, "");
    }
}

unittest {
    mixin CreateLogger;
    auto sink = new StdoutSink;
    Logger log = Logger(sink);
    auto results = new AllColectionResults;
    auto scanner = new CodebaseScanner!(AllColectionResults, AllCollectingListener)(results, sink);
    
    scanner.scan!(toScan!("ex1"))();
    
    with(CollectionEvent) 
    {
        assert(results.results[0] == ColletionResult(SCANNABLE, to!string(toScan!("ex1"))));
        assert(
            Set!ColletionResult.of(results.results[1..$]) 
            == 
            Set!ColletionResult.of([
                ColletionResult(TYPE, "ex1.scan_aggregates.C"), 
                ColletionResult(TYPE, "ex1.scan_aggregates.I"), 
                ColletionResult(TYPE, "ex1.scan_aggregates.C2"), 
                ColletionResult(TYPE, "ex1.scan_aggregates.JustEnum"), 
                ColletionResult(TYPE, "ex1.scan_aggregates.StringEnum"), 
                ColletionResult(TYPE, "ex1.scan_aggregates.Struct")
            ])
        );
    }
    
    results.results = [];
    
    scanner.scan!(toScan!("ex2"))();

    with(CollectionEvent) 
    {
        assert(results.results[0] == ColletionResult(SCANNABLE, to!string(toScan!("ex2"))));
        assert(
            Set!ColletionResult.of(results.results[1..$]) 
            == 
            Set!ColletionResult.of([
                ColletionResult(TYPE, "ex2.sub1.m1.C"), 
                ColletionResult(TYPE, "ex2.sub2.m2.I")
            ])
        );
    }
    
    results.results = [];
    
    scanner.scan!(toScan!("bundles"))();

    with(CollectionEvent) 
    {
        assert(results.results[0] == ColletionResult(SCANNABLE, to!string(toScan!("bundles"))));
        log.info.emit(results.results);
        assert(
            Set!ColletionResult.of(results.results[1..$]) 
            == 
            Set!ColletionResult.of([
                ColletionResult(BUNDLE, "bundles.content.onlysubpkgs._scantest_bundle"), 
                ColletionResult(BUNDLE, "bundles.content.onlysubpkgs.onlysubmods._scantest_bundle"), 
                ColletionResult(BUNDLE, "bundles.content.onlysubpkgs.mixed._scantest_bundle"), 
                ColletionResult(BUNDLE, "bundles.content.onlysubpkgs.mixed.empty._scantest_bundle")
            ])
        );
    }
    
    results.results = [];
    
    scanner.freeze();
    
    with(CollectionEvent) 
    {
        assert(results.results[0] == ColletionResult(FREEZE, ""));
    }
}
