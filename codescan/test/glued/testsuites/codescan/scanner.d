module glued.testsuites.codescan.scanner;

import std.conv;
import std.traits;
import std.range;

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
    assert(scanner.frozen);
    //todo assert throws if we scan now
    
    with(CollectionEvent) 
    {
        assert(results.results[0] == ColletionResult(FREEZE, ""));
    }
    
    log.info.emit("Scanning one by one  with single listener works");
}

unittest {
    mixin CreateLogger;
    auto sink = new StdoutSink;
    Logger log = Logger(sink);
    auto results = new AllColectionResults;
    auto scanner = new CodebaseScanner!(AllColectionResults, AllCollectingListener)(results, sink);
    
    scanner.scan!(toScan!("ex1"), toScan!("ex2"), toScan!("bundles"))();
    scanner.freeze();
    assert(scanner.frozen);
    //todo assert throws if we scan now
    
    with(CollectionEvent) 
    {
        auto ex1Expected = Set!ColletionResult.of([
            ColletionResult(TYPE, "ex1.scan_aggregates.C"), 
            ColletionResult(TYPE, "ex1.scan_aggregates.I"), 
            ColletionResult(TYPE, "ex1.scan_aggregates.C2"), 
            ColletionResult(TYPE, "ex1.scan_aggregates.JustEnum"), 
            ColletionResult(TYPE, "ex1.scan_aggregates.StringEnum"), 
            ColletionResult(TYPE, "ex1.scan_aggregates.Struct")
        ]);
        auto ex2Expected = Set!ColletionResult.of([
            ColletionResult(TYPE, "ex2.sub1.m1.C"), 
            ColletionResult(TYPE, "ex2.sub2.m2.I")
        ]);
        auto bundlesExpected = Set!ColletionResult.of([
            ColletionResult(BUNDLE, "bundles.content.onlysubpkgs._scantest_bundle"), 
            ColletionResult(BUNDLE, "bundles.content.onlysubpkgs.onlysubmods._scantest_bundle"), 
            ColletionResult(BUNDLE, "bundles.content.onlysubpkgs.mixed._scantest_bundle"), 
            ColletionResult(BUNDLE, "bundles.content.onlysubpkgs.mixed.empty._scantest_bundle")
        ]);
        
        auto setBetween(size_t i1, size_t i2){
            return Set!ColletionResult.of(results.results[i1..i2]);
        }
    
        size_t idx = 0;
        assert(results.results[idx] == ColletionResult(SCANNABLE, to!string(toScan!("ex1"))));
        
        idx += 1;
        assert(setBetween(idx, idx + ex1Expected.length) == ex1Expected);
        
        idx += ex1Expected.length;
        assert(results.results[idx] == ColletionResult(SCANNABLE, to!string(toScan!("ex2"))));
        
        idx += 1;
        assert(setBetween(idx, idx + ex2Expected.length) == ex2Expected);
        
        idx += ex2Expected.length;
        assert(results.results[idx] == ColletionResult(SCANNABLE, to!string(toScan!("bundles"))));
        
        idx += 1;
        assert(setBetween(idx, idx + bundlesExpected.length) == bundlesExpected);
        
        idx += bundlesExpected.length;
        
        assert(results.results[idx] == ColletionResult(FREEZE, ""));
        
        idx += 1;
        assert(idx == results.results.length);
    }
    
    log.info.emit("Scanning several scannables at once with single listener works");
}

class ByKindResults 
{
    Scannable[] scannables;
    string[] typeNames;
    string[] bundleModNames;
    bool frozen = false;
}

class ScannableListener: Listener!ByKindResults 
{
    ByKindResults results = null;

    void init(ByKindResults results)
    {
        this.results = results;
    }

    void onScannable(alias scannable)() if (isScannable!scannable) 
    {
        results.scannables ~= scannable;
    }
    
    void onType(T)()
    {
    }
    
    void onBundleModule(string modName)()
    {
    }
    
    void onScannerFreeze()
    {
    }
}

class TypeListener: Listener!ByKindResults 
{
    ByKindResults results = null;

    void init(ByKindResults results)
    {
        this.results = results;
    }

    void onScannable(alias scannable)() if (isScannable!scannable) 
    {
    }
    
    void onType(T)()
    {
        results.typeNames ~= fullyQualifiedName!T;
    }
    
    void onBundleModule(string modName)()
    {
    }
    
    void onScannerFreeze()
    {
    }
}

class BundleListener: Listener!ByKindResults 
{
    ByKindResults results = null;

    void init(ByKindResults results)
    {
        this.results = results;
    }

    void onScannable(alias scannable)() if (isScannable!scannable) 
    {
    }
    
    void onType(T)()
    {
    }
    
    void onBundleModule(string modName)()
    {
        results.bundleModNames ~= modName;
    }
    
    void onScannerFreeze()
    {
    }
}

class FreezeListener: Listener!ByKindResults 
{
    ByKindResults results = null;

    void init(ByKindResults results)
    {
        this.results = results;
    }

    void onScannable(alias scannable)() if (isScannable!scannable) 
    {
    }
    
    void onType(T)()
    {
    }
    
    void onBundleModule(string modName)()
    {
    }
    
    void onScannerFreeze()
    {
        results.frozen = true;
    }
}

unittest {
    mixin CreateLogger;
    auto sink = new StdoutSink;
    Logger log = Logger(sink);
    auto results = new ByKindResults;
    auto scanner = new CodebaseScanner!(ByKindResults, ScannableListener, TypeListener, BundleListener, FreezeListener)(results, sink);
    
    scanner.scan!(toScan!("ex1"))();
    
    with(CollectionEvent) 
    {
        assert(results.scannables == [toScan!("ex1")]);
        assert(Set!string.of(results.typeNames) == Set!string.of([
            "ex1.scan_aggregates.C", 
            "ex1.scan_aggregates.I", 
            "ex1.scan_aggregates.C2", 
            "ex1.scan_aggregates.JustEnum", 
            "ex1.scan_aggregates.StringEnum", 
            "ex1.scan_aggregates.Struct"
        ]));
        assert(results.bundleModNames.empty);
        assert(!results.frozen);
    }
    
    scanner.scan!(toScan!("ex2"))();
    
    with(CollectionEvent) 
    {
        assert(results.scannables == [toScan!("ex1"), toScan!("ex2")]);
        assert(Set!string.of(results.typeNames) == Set!string.of([
            "ex1.scan_aggregates.C", 
            "ex1.scan_aggregates.I", 
            "ex1.scan_aggregates.C2", 
            "ex1.scan_aggregates.JustEnum", 
            "ex1.scan_aggregates.StringEnum", 
            "ex1.scan_aggregates.Struct",
            "ex2.sub1.m1.C",
            "ex2.sub2.m2.I"
        ]));
        assert(results.bundleModNames.empty);
        assert(!results.frozen);
    }

    scanner.scan!(toScan!("bundles"))();

    with(CollectionEvent) 
    {
        assert(results.scannables == [toScan!("ex1"), toScan!("ex2"), toScan!("bundles")]);
        assert(Set!string.of(results.typeNames) == Set!string.of([
            "ex1.scan_aggregates.C", 
            "ex1.scan_aggregates.I", 
            "ex1.scan_aggregates.C2", 
            "ex1.scan_aggregates.JustEnum", 
            "ex1.scan_aggregates.StringEnum", 
            "ex1.scan_aggregates.Struct",
            "ex2.sub1.m1.C",
            "ex2.sub2.m2.I"
        ]));
        assert(Set!string.of(results.bundleModNames) == Set!string.of([
            "bundles.content.onlysubpkgs._scantest_bundle",
            "bundles.content.onlysubpkgs.onlysubmods._scantest_bundle",
            "bundles.content.onlysubpkgs.mixed._scantest_bundle",
            "bundles.content.onlysubpkgs.mixed.empty._scantest_bundle"
        ]));
        assert(!results.frozen);
    }

    scanner.freeze();
    with(CollectionEvent) 
    {
        assert(results.scannables == [toScan!("ex1"), toScan!("ex2"), toScan!("bundles")]);
        assert(Set!string.of(results.typeNames) == Set!string.of([
            "ex1.scan_aggregates.C",
            "ex1.scan_aggregates.I", 
            "ex1.scan_aggregates.C2", 
            "ex1.scan_aggregates.JustEnum", 
            "ex1.scan_aggregates.StringEnum", 
            "ex1.scan_aggregates.Struct",
            "ex2.sub1.m1.C",
            "ex2.sub2.m2.I"
        ]));
        assert(Set!string.of(results.bundleModNames) == Set!string.of([
            "bundles.content.onlysubpkgs._scantest_bundle", 
            "bundles.content.onlysubpkgs.onlysubmods._scantest_bundle",
            "bundles.content.onlysubpkgs.mixed._scantest_bundle",
            "bundles.content.onlysubpkgs.mixed.empty._scantest_bundle"
        ]));
        assert(results.frozen);
    }
    //todo assert throws if we scan now
    
    log.info.emit("Scanning one by one with several listener works");
}

unittest {
    mixin CreateLogger;
    auto sink = new StdoutSink;
    Logger log = Logger(sink);
    auto results = new ByKindResults;
    auto scanner = new CodebaseScanner!(ByKindResults, ScannableListener, TypeListener, BundleListener, FreezeListener)(results, sink);
    
    scanner.scan!(toScan!("ex1"), toScan!("ex2"), toScan!("bundles"))();
    //todo could check the same state as below, but !frozen
    scanner.freeze();
    with(CollectionEvent) 
    {
        assert(results.scannables == [toScan!("ex1"), toScan!("ex2"), toScan!("bundles")]);
        assert(Set!string.of(results.typeNames) == Set!string.of([
            "ex1.scan_aggregates.C",
            "ex1.scan_aggregates.I", 
            "ex1.scan_aggregates.C2", 
            "ex1.scan_aggregates.JustEnum", 
            "ex1.scan_aggregates.StringEnum", 
            "ex1.scan_aggregates.Struct",
            "ex2.sub1.m1.C",
            "ex2.sub2.m2.I"
        ]));
        assert(Set!string.of(results.bundleModNames) == Set!string.of([
            "bundles.content.onlysubpkgs._scantest_bundle", 
            "bundles.content.onlysubpkgs.onlysubmods._scantest_bundle",
            "bundles.content.onlysubpkgs.mixed._scantest_bundle",
            "bundles.content.onlysubpkgs.mixed.empty._scantest_bundle"
        ]));
        assert(results.frozen);
    }
    //todo assert throws if we scan now
    
    log.info.emit("Scanning several scannables at once with several listener works");
}
