module glued.context.bundles;

import std.algorithm;
import std.range;

import optional;

/**
 * Generalization of the idea of a read-only text file.
 */
interface Asset {
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
    
    Optional!Asset find(string path);
    
    final Asset get(string path){
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

class GluedAsset: Asset {
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
    alias backend = def.Assets;
//    private string[string] backend;
    
    bool exists(string path){
        return dirName(path) == directoryName && baseName(path) in backend;
    }
    
    Optional!Asset find(string path) {
        if (!exists(path))
            return no!Asset;
        //fixme I guess we could copy even less if file impl would also have Definition imported
        return new GluedAsset(path, backend[baseName(path)]).some;
    }
}

//todo silent assumption - file is in UTF-8/aligned with string, not wstring, etc
class FileAsset: Asset {
    import std.file;

    private string fullPath;
    
    this(string path){
        assert(path.exists && path.isFile);
        fullPath = path;
    }

    @property 
    string scheme(){
        return "file";
    }
    
    @property
    string path(){
        return fullPath;
    }
    
    @property
    string content(){
        return readText(fullPath);
    }
}

class DirectoryBundle: Bundle {
    import std.path;
    import std.file;
    
    private string dirPath;
    
    this(string path){
        assert(path.exists && path.isDir); //todo exception
        dirPath = path;
    }
    
    @property
    string scheme(){
        return "file";
    }
    
    bool exists(string path){
        return dirPath.chainPath(path).exists;
    }
    
    Optional!Asset find(string path){
        if (!exists(path)){
            return no!Asset;
        }
        //fixme what if between find() and asset.content file will be removed? maybe its a good idea to read it eagerly?
        return (cast(Asset) new FileAsset(cast(string) dirPath.chainPath(path).array)).some;
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
    
    Optional!Asset find(string scheme, string path){
        return containing(scheme, path).map!(b => b.get(path)).toOptional;
    }
    
    final Asset get(string scheme, string path){
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
