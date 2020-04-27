module glued.pathtree;

import std.range;
import std.algorithm;
import std.typecons;
import std.traits;
import std.meta;

import optional;


/**
 * Data structure that wraps the actual value of the node with metadata used
 * for versioning of node values.
 */
class ValueChainLink(Data) {
    ///Version number of the value, counting from 0 (initial value)
    size_t _versionNo;
    ///Payload
    Optional!Data _data; //fixme this should be plain Data, not Optional!Data
    ///Optional link to previous value with metadata
    Optional!(typeof(this)) _previousValue;
    
    this(size_t v, Optional!Data d, Optional!ValueChainLink p){
        _versionNo = v;
        _data = d;
        _previousValue = p;
    }
    
    @property
    size_t versionNo(){
        return _versionNo;
    }
    
    @property
    Optional!Data data(){
        return _data;
    }
    
    @property
    Optional!(typeof(this)) previousValue(){
        return _previousValue;
    }
}
/**
 * ValueChainLink with actual path under which it is stored. Used when 
 * $(D_PSYMBOL resolve)ing instead of $(D_PSYMBOL get)ing values, allows
 * to inspect not only the value obtained from resolution, but also its
 * origins.
 */
alias ValueChainLinkWithCoordinates(Data) = Tuple!(ValueChainLink!Data, "valueChainLink", string, "realPath");

class PathTreeNode(Data) {
    alias Link = ValueChainLink!Data;
    alias LinkWithCoordinates = ValueChainLinkWithCoordinates!Data;
    
    private string fullPath;
    private PathTreeNode!Data[string] children;
    private Optional!(Link) valueChainLink = no!(Link);
    
    this(string path){
        fullPath = path;
    }
    
    //
    // WRITE STACK
    // impl
    
    private void put(string[] pathComponents, Data data){
        if (pathComponents.empty){
            size_t nextVersion = (valueChainLink.empty ? -1 : valueChainLink.front().versionNo) + 1;
            auto prev = valueChainLink;
            Link newValueChainLink = new Link(nextVersion, data.some, prev);
            valueChainLink = newValueChainLink.some;
        } else {
            auto head = pathComponents[0];
            auto tail = pathComponents[1..$];
            if (!(head in children)){
                string childPath = (this.fullPath.empty ? "" : this.fullPath~".")~head;
                children[head] = new PathTreeNode!Data(childPath);
            }
            children[head].put(tail, data);
        }
    }
    
    //public API
    
    void put(string path, Data data){
        put(path.split("."), data);
    }
    
    //todo pop(pathComponents) (decrements versionNo, brings back previous val, returns removed value)
    //todo popToVersion(pathComponents, size_t targetVersion) (pops number of times, returns array of values in order of poping, if targetVersion>current or targetVersion<-1 - exception, if target == current - no-op)
    
    //
    // READ STACK
    // impl
    
    private Optional!Link getValueChainLink(string[] pathComponents){
        if (pathComponents.empty){
            return valueChainLink;
        } else {
            return pathComponents[0] in children ? 
                    children[pathComponents[0]].getValueChainLink(pathComponents[1..$]) : 
                    no!Link;
        }
    }
    
    private Optional!LinkWithCoordinates resolveValueChainLinkWithCoordinates(string[] pathComponents){
        if (pathComponents.empty){
            return valueChainLink.map!(x => LinkWithCoordinates(x, fullPath)).toOptional;
        }
        auto deeperResult = pathComponents[0] in children ? 
                                children[pathComponents[0]].resolveValueChainLinkWithCoordinates(pathComponents[1..$]) : 
                                no!LinkWithCoordinates;
        if (deeperResult.empty){
            return valueChainLink.map!(x => LinkWithCoordinates(x, fullPath)).toOptional;
        }
        return deeperResult;
    }
    
    //public API
    
    Optional!Link getValueChainLink(string path) {
        return getValueChainLink(path.split("."));
    }
    
    Optional!LinkWithCoordinates resolveValueChainLinkWithCoordinates(string path) {
        return resolveValueChainLinkWithCoordinates(path.split("."));
    }
    
    Optional!Data get(string path) {
        return getValueChainLink(path).map!(x => x.data).joiner.toOptional;
    }
    
    Optional!size_t getVersion(string path) {
        return getValueChainLink(path).map!(x => x.versionNo).toOptional;
    }
    
    Optional!Link resolveValueChainLink(string path) {
        return resolveValueChainLinkWithCoordinates(path).map!(x => x.valueChainLink).toOptional;
    }
    
    Optional!string resolveCoordinates(string path) {
        return resolveValueChainLinkWithCoordinates(path).map!(x => x.realPath).toOptional;
    }
    
    Optional!Data resolve(string path) {
        return resolveValueChainLink(path).map!(x => x.data).joiner.toOptional;
    }
    
    Optional!size_t resolveVersion(string path) {
        return resolveValueChainLink(path).map!(x => x.versionNo).toOptional;
    }
}

/**
 * Path tree is a tree where each node has a path assigned. Path is joined with dots
 * which represent tree hierarchy. Each node can hold an optional value. Values
 * are overridable, but history of values is kept, so we can analyze version
 * number for a given node (number of times $(D_PSYMBOL put) was used with that 
 * node as target) and revert to previous version of that node as well.
 *
 * Besides retrieving exact value with $(D_PSYMBOL get), we can also 
 * $(D_PSYMBOL resolve) a path. In this case if a node specified by path has no 
 * value, we fall back to parent node (with fallback to grandparent node, etc). 
 * This mode of retrieving values is very useful when using this structure as 
 * description of some other hierarchy, e.g. package structure and its related
 * log levels.
 */
class PathTree(Data) {
    alias Link = ValueChainLink!Data;
    alias LinkWithCoordinates = ValueChainLinkWithCoordinates!Data;
    
    private PathTreeNode!Data root = new PathTreeNode!Data("");
    
    /**
     * Assign $(D_PSYMBOL data) to a node specified by $(D_PSYMBOL path). If that node
     * already had value, replace it with $(D_PSYMBOL data), but increment value 
     * version and keep reference to previous value.
     */
    void put(string path, Data data){
        root.put(path, data);
    }
    
    /**
     * Returns: $(D_PSYMBOL some) over data stored under this exact $(D_PSYMBOL path); 
     * empty optional if no value was assigned.
     */
    Optional!Data get(string path) {
        return root.get(path);
    }
    
    /**
     * Returns: $(D_PSYMBOL some) over version number (counted from 0) of data 
     * stored under this exact $(D_PSYMBOL path); empty optional if no value was assigned.
     */
    Optional!size_t getVersion(string path) {
        return root.getVersion(path);
    }
    
    Optional!Link getValueChainLink(string path) { //todo untested
        return root.getValueChainLink(path);
    }

    /**
     * Returns: $(D_PSYMBOL some) over data stored under this $(D_PSYMBOL path) or 
     * its closest ancestor; empty optional if no value was assigned anywhere 
     * from that node up to the root of the tree.
     */
    Optional!Data resolve(string path) {
        return root.resolve(path);
    }
    
    Optional!size_t resolveVersion(string path) {
        return root.resolveVersion(path);
    }
    
    Optional!Link resolveValueChainLink(string path) { //todo untested
        return root.resolveValueChainLink(path);
    }
    
    /**
     * Returns: real path of the value that would be returned from 
     * $(D_PSYMBOL resolve(path)) wrapped into optional; empty if aforementioned 
     * call would result in empty optional.
     */
    Optional!string resolveCoordinates(string path) {
        return root.resolveCoordinates(path);
    }
    
    Optional!LinkWithCoordinates resolveValueChainLinkWithCoordinates(string path) { //todo untested
        return root.resolveValueChainLinkWithCoordinates(path);
    }
    
}

//todo move to another source set
///basic usage
unittest {
    PathTree!string tree = new PathTree!string;

    tree.put("abc.def.g", "x");
    tree.put("abc.def.g", "y");

    assert(tree.get("abc.def.g") == "y".some);
    assert(tree.getVersion("abc.def.g") == 1.some);
    
    assert(tree.get("abc.def.g.h") == no!string);
    assert(tree.getVersion("abc.def.g.h") == no!size_t);
    
    assert(tree.resolve("abc.def.g.h") == "y".some);
    assert(tree.resolveVersion("abc.def.g.h") == 1.some);
    assert(tree.resolveCoordinates("abc.def.g.h") == "abc.def.g".some);
}
