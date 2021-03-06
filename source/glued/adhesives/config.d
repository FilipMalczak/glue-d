module glued.adhesives.config;

import std.algorithm;

public import glued.pathtree;
import glued.logging;

import glued.adhesives.bundles;

import optional;
import properd;

//todo no tests at all

struct ConfigEntry {
    string text;
    Asset source;
}

//todo Environment seems more natural
//todo would this gain anything from making previous value versions visible or reachable?
class Config {
    //todo CreateLogger -> DefineLogger; CreateLogger(name) = DefineLogger + Logger <name>
    mixin CreateLogger;
    Logger log;
    
    this(LogSink sink){
        log = Logger(sink);
    }
    
    private PathTree!ConfigEntry backend = new ConcretePathTree!ConfigEntry();
    
    void feed(Asset asset){
        log.debug_.emit("Feeding config from ", asset);
        auto aa = parseProperties(asset.content);
        foreach(k; aa.keys()){
            backend.put(k, ConfigEntry(aa[k], asset));
        }
    }
    
    //todo introduce interface ViewClosure(Result), normalize all closures, e.g. ValuesClosure: ViewClosure!string?
    
    @property
    PathTreeView!ConfigEntry view(){
        return backend;
    }
    
    struct ValuesClosure {
        private Config config;
         
        string get(string path){
            return find(path).front();
        }
        
        Optional!string find(string path){
            return config.backend.get(path).map!(x => x.text).toOptional;
        }
        
        Optional!string resolve(string path){
            return config.backend.resolve(path).map!(x => x.text).toOptional;
        }
    }
    
    @property
    ValuesClosure values(){
        return ValuesClosure();
    }
    
    struct SourcesClosure {
        private Config config;
         
        Asset get(string path){
            return find(path).front();
        }
        
        Optional!Asset find(string path){
            return config.backend.get(path).map!(x => x.source).toOptional;
        }
        
        Optional!Asset resolve(string path){
            return config.backend.resolve(path).map!(x => x.source).toOptional;
        }
    }
    
    @property
    SourcesClosure sources(){
        return SourcesClosure();
    }
    
    struct EntriesClosure {
        private Config config;
         
        ConfigEntry get(string path){
            return find(path).front();
        }
        
        Optional!ConfigEntry find(string path){
            return config.backend.get(path);
        }
        
        Optional!ConfigEntry resolve(string path){
            return config.backend.resolve(path);
        }
    }
    
    @property
    EntriesClosure entries(){
        return EntriesClosure();
    }
}
