module glued.context.bundles;

import std.algorithm;
import std.range;

import optional;

//todo rename to Asset
interface BundledFile {
    @property 
    string scheme();
    
    @property
    string path();
    
    @property //todo uri? urn? consider differences, I think its urn
    final string url(){
        return scheme~"://"~path;
    }
    
    @property
    string content();
}

interface Bundle {
    //todo add ls(), same goes for registrar, it should return urls

    @property
    string scheme();
    
    bool exists(string path);
    
    Optional!BundledFile find(string path);
    
    final BundledFile get(string path){
        auto result = find(path);
        if (result.empty)
            return null;
        return result.front();
    }
    
    final Optional!string findContent(string path){
        return find(path).map!(bf => bf.content).toOptional;
    }
    
    final string getContent(string path){
        return get(path).content;
    }
}

class GluedBundledFile: BundledFile {
    @property
    string scheme(){
        return "glue";
    }
    
    private string _path;
    private string _content;
    
    this(string p, string c){
        _path = p;
        _content = c;
    }
    
    @property
    string path(){
        return _path;
    }
    
    @property
    string content(){
        return _content;
    }
}

class GluedBundle(string modName): Bundle {
    import std.path;

    @property
    string scheme(){
        return "glue";
    }
    
    enum directoryName = modName.split(".").join(dirSeparator);
    
    mixin("import "~modName~";");
    alias def = BundleDefinition;
    alias backend = def.bundledFiles;
//    private string[string] backend;
    
    bool exists(string path){
        return dirName(path) == directoryName && baseName(path) in backend;
    }
    
    Optional!BundledFile find(string path) {
        if (!exists(path))
            return no!BundledFile;
        //fixme I guess we could copy even less if file impl would also have Definition imported
        return new GluedBundledFile(path, backend[baseName(path)]).some;
    }
}

class BundleRegistrar {
    private Bundle[] backend;
    
    void register(Bundle bundle){
        backend ~= bundle;
    }
    
    void register(string modName)(){
        register(buildBundle!modName());
    }
    
    private Bundle buildBundle(string modName)(){
        return new GluedBundle!modName;
    }
    
    private Optional!Bundle containing(string scheme, string path){
        Bundle[] containing;
        foreach (b; backend){
            if (b.scheme == scheme && b.exists(path)){
                containing ~= b;
            }
        }
        if (containing.empty)
            return no!Bundle;
        if (containing.length == 1)
            return containing[0].some;
        assert(false); //todo exception
    }
    
    bool exists(string scheme, string path){
        return !containing(scheme, path).empty;
    }
    
    Optional!BundledFile find(string scheme, string path){
        return containing(scheme, path).map!(b => b.get(path)).toOptional;
    }
    
    final BundledFile get(string scheme, string path){
        auto result = find(scheme, path);
        if (result.empty)
            return null;
        return result.front();
    }
    
    final Optional!string findContent(string scheme, string path){
        return find(scheme, path).map!(bf => bf.content).toOptional;
    }
    
    final string getContent(string scheme, string path){
        return get(scheme, path).content;
    }
}
