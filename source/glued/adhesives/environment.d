module glued.adhesives.environment;

import std.algorithm;

public import glued.pathtree;
import glued.logging;

import glued.adhesives.bundles;

import optional;
import properd;

//todo no tests at all

struct EnvironmentEntry {
    string text;
    Asset source;
}

//todo would this gain anything from making previous value versions visible or reachable?
class Environment {
    //todo CreateLogger -> DefineLogger; CreateLogger(name) = DefineLogger + Logger <name>
    mixin CreateLogger;
    Logger log;
    
    this(LogSink sink){
        log = Logger(sink);
    }
    
    private PathTree!EnvironmentEntry backend = new ConcretePathTree!EnvironmentEntry();
    
    //todo this should become feed(PropertySource)
    void feed(Asset asset){
        log.debug_.emit("Feeding environment from ", asset);
        auto aa = parseProperties(asset.content);
        foreach(k; aa.keys()){
            backend.put(Path.parse(k), EnvironmentEntry(aa[k], asset));
        }
    }
    
    //todo introduce interface ViewClosure(Result), normalize all closures, e.g. ValuesClosure: ViewClosure!string?
    
    @property
    PathTreeView!EnvironmentEntry view(){
        return backend;
    }
    
    struct ValuesClosure {
        private Environment environment;
         
        string get(string path){
            return find(path).front();
        }
        
        Optional!string find(string path){
            return environment.backend.get(Path.parse(path)).map!(x => x.text).toOptional;
        }
        
        Optional!string resolve(string path){
            return environment.backend.resolve(Path.parse(path)).map!(x => x.text).toOptional;
        }
    }
    
    @property
    ValuesClosure values(){
        return ValuesClosure();
    }
    
    struct SourcesClosure {
        private Environment environment;
         
        Asset get(string path){
            return find(path).front();
        }
        
        Optional!Asset find(string path){
            return environment.backend.get(Path.parse(path)).map!(x => x.source).toOptional;
        }
        
        Optional!Asset resolve(string path){
            return environment.backend.resolve(Path.parse(path)).map!(x => x.source).toOptional;
        }
    }
    
    @property
    SourcesClosure sources(){
        return SourcesClosure();
    }
    
    struct EntriesClosure {
        private Environment environment;
         
        EnvironmentEntry get(string path){
            return find(path).front();
        }
        
        Optional!EnvironmentEntry find(string path){
            return environment.backend.get(Path.parse(path));
        }
        
        Optional!EnvironmentEntry resolve(string path){
            return environment.backend.resolve(Path.parse(path));
        }
    }
    
    @property
    EntriesClosure entries(){
        return EntriesClosure();
    }
}
