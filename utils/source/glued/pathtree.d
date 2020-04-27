module glued.pathtree;

import std.range;
import std.algorithm;
import std.typecons;
import std.traits;
import std.meta;

import std.string: strip;

import optional;


/**
 * Data structure that wraps the actual value of the node with metadata used
 * for versioning of node values.
 */
class ValueChain(Data) {
    ///Version number of the value, counting from 0 (initial value)
    size_t _versionNo;
    ///Payload
    Optional!Data _data; //fixme this should be plain Data, not Optional!Data
    ///Optional link to previous value with metadata
    Optional!(typeof(this)) _previousValue;
    
    this(size_t v, Optional!Data d, Optional!ValueChain p){
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
 * ValueChain with actual path under which it is stored. Used when 
 * $(D_PSYMBOL resolve)ing instead of $(D_PSYMBOL get)ing values, allows
 * to inspect not only the value obtained from resolution, but also its
 * origins.
 */
alias ValueChainWithCoordinates(Data) = Tuple!(ValueChain!Data, "valueChain", string, "realPath");

class PathTreeNode(Data) {
    alias Link = ValueChain!Data;
    alias LinkWithCoordinates = ValueChainWithCoordinates!Data;
    
    private string fullPath;
    private PathTreeNode!Data[string] children;
    private Optional!(Link) valueChain = no!(Link); //todo rename to valueChain
    
    this(string path){
        fullPath = path;
    }
    
    //
    // WRITE STACK
    // impl
    
    private void put(string[] pathComponents, Data data){
        //todo this introduces a silent feature - root can have value, paths can start and end with dots - cover that with tests! or check some conditions in public put
        pathComponents = pathComponents.filter!(x => !x.strip().empty).array;
        if (pathComponents.empty){
            size_t nextVersion = (valueChain.empty ? -1 : valueChain.front().versionNo) + 1;
            auto prev = valueChain;
            Link newValueChain = new Link(nextVersion, data.some, prev);
            valueChain = newValueChain.some;
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
    
    void put(string path, Data data){
        put(path.split("."), data);
    }
    
    private Optional!Link getValueChain(string[] pathComponents){
        if (pathComponents.empty){
            return valueChain;
        } else {
            return pathComponents[0] in children ? 
                    children[pathComponents[0]].getValueChain(pathComponents[1..$]) : 
                    no!Link;
        }
    }
    
    private Optional!LinkWithCoordinates resolveValueChainWithCoordinates(string[] pathComponents, string upToRoot){
        if (pathComponents.empty){
            return valueChain.map!(x => LinkWithCoordinates(x, fullPath)).toOptional;
        }
        auto deeperResult = pathComponents[0] in children ? 
                                children[pathComponents[0]].resolveValueChainWithCoordinates(pathComponents[1..$], upToRoot) : 
                                no!LinkWithCoordinates;
        if (deeperResult.empty && fullPath.startsWith(upToRoot)){
            return valueChain.map!(x => LinkWithCoordinates(x, fullPath)).toOptional;
        }
        return deeperResult;
    }
    
    Optional!Link getValueChain(string path) {
        return getValueChain(path.split("."));
    }
    
    Optional!LinkWithCoordinates resolveValueChainWithCoordinates(string path, string upToRoot="") {
        return resolveValueChainWithCoordinates(path.split("."), upToRoot);
    }
    
}

//todo view!D should get subtree(string fromNode) -> view!D, withPathsMapped(PathMapper) -> view!D, withValuesMapped(ValueMapper(D, T)) -> view!T
//alias PathMapper = string delegate(string); // viewPath -> backendPath
//alias ValueMapper(T, T2) = T2 delegate(string, T); //(viewPath, backendValue) -> viewValue

interface PathTreeView(Data){
    alias Link = ValueChain!Data;
    
    Optional!Link getValueChain(string path);
    
    Optional!Link resolveValueChain(string path);
    
    /**
     * Returns: $(D_PSYMBOL some) over data stored under this exact $(D_PSYMBOL path); 
     * empty optional if no value was assigned.
     */
    final Optional!Data get(string path) {
        return getValueChain(path).map!(x => x.data).joiner.toOptional;
    }
    
    /**
     * Returns: $(D_PSYMBOL some) over version number (counted from 0) of data 
     * stored under this exact $(D_PSYMBOL path); empty optional if no value was assigned.
     */
    final Optional!size_t getVersion(string path) {
        return getValueChain(path).map!(x => x.versionNo).toOptional;
    }
    
    /**
     * Returns: $(D_PSYMBOL some) over data stored under this $(D_PSYMBOL path) or 
     * its closest ancestor; empty optional if no value was assigned anywhere 
     * from that node up to the root of the tree.
     */
    final Optional!Data resolve(string path) {
        return resolveValueChain(path).map!(x => x.data).joiner.toOptional;
    }
    
    final Optional!size_t resolveVersion(string path) {
        return resolveValueChain(path).map!(x => x.versionNo).toOptional;
    }
}

//todo should be an interface
abstract class PathTree(Data): PathTreeView!Data {
    alias Link = ValueChain!Data;
    alias LinkWithCoordinates = ValueChainWithCoordinates!Data;
    
    /**
     * Assign $(D_PSYMBOL data) to a node specified by $(D_PSYMBOL path). If that node
     * already had value, replace it with $(D_PSYMBOL data), but increment value 
     * version and keep reference to previous value.
     */
    void put(string path, Data data);
    
    Optional!LinkWithCoordinates resolveValueChainWithCoordinates(string path, string upToRoot="");
    
    final override Optional!Link resolveValueChain(string path) {
        return resolveValueChainWithCoordinates(path).map!(x => x.valueChain).toOptional;
    }
    
    /**
     * Returns: real path of the value that would be returned from 
     * $(D_PSYMBOL resolve(path)) wrapped into optional; empty if aforementioned 
     * call would result in empty optional.
     */
    final Optional!string resolveCoordinates(string path) {
        return resolveValueChainWithCoordinates(path).map!(x => x.realPath).toOptional;
    }
    
    //todo pop(pathComponents) (decrements versionNo, brings back previous val, returns removed value)
    //todo popToVersion(pathComponents, size_t targetVersion) (pops number of times, returns array of values in order of poping, if targetVersion>current or targetVersion<-1 - exception, if target == current - no-op); this should probably be external function, so we 
    //can provide default, but impl can optimize it as well
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
class ConcretePathTree(Data): PathTree!Data {
    private PathTreeNode!Data root = new PathTreeNode!Data("");
    
    override void put(string path, Data data){
        root.put(path, data);
    }
    
    Optional!Link getValueChain(string path) { //todo untested
        return root.getValueChain(path);
    }

    override Optional!LinkWithCoordinates resolveValueChainWithCoordinates(string path, string upToRoot="") { //todo untested
        return root.resolveValueChainWithCoordinates(path, upToRoot);
    }
    
}

//todo move to another source set
///basic usage
unittest {
    PathTree!string tree = new ConcretePathTree!string;

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
