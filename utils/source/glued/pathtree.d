module glued.pathtree;

import std.range;
import std.algorithm;
import std.typecons;
import std.traits;
import std.meta;

import std.string: strip;

import optional;

struct Path 
{
    enum SEPARATOR = ".";
    
    enum EMPTY = Path([]);

    private string[] _components;
    
    this(string[] _components)
    {
        this._components = _components;
    }
    
    static parse(string path, string separator=SEPARATOR)
    {
        return Path(path.split(separator).array);
    }
    
    @property
    string[] components()
    {
        return _components[];
    }
    
    @property
    string fullPath(string separator=SEPARATOR)
    {
        return _components.join(separator);
    }
    
    @property
    bool empty()
    {
        return _components.empty;
    }
    
    Optional!string head()
    {
        if (empty)
            return no!string;
        return _components[0].some;
    }
    
    @property
    Path tail()
    {
        return Path(_components[1..$]);
    }
    
    @property
    Optional!string name()
    {
        if (empty)
            return no!string;
        return _components[$-1].some;
    }
    
    Path child(string name)
    {
        return Path(_components ~ [name]);
    }
    
    Path join(Path another)
    {
        return Path(_components ~ another._components);
    }
}

/**
 * Data structure that wraps the actual value of the node with metadata used
 * for versioning of node values.
 */
interface ValueChain(Data) {
    ///Version number of the value, counting from 0 (initial value)
    @property
    size_t versionNo();
    
    ///Payload
    @property
    Optional!Data data(); //fixme this should be plain Data, not Optional!Data
    
    ///Optional link to previous value with metadata
    @property
    Optional!(ValueChain!Data) previousValue();
    
    final static class SimpleValueChain: ValueChain!Data {
        size_t _versionNo;
        Optional!Data _data; //fixme this should be plain Data, not Optional!Data
        Optional!(ValueChain!Data) _previousValue;
        
        this(size_t v, Optional!Data d, Optional!(ValueChain!Data) p){
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
        Optional!(ValueChain!Data) previousValue(){
            return _previousValue;
        }
    }
    
    static final ValueChain!Data of(size_t v, Optional!Data d, Optional!(ValueChain!Data) p){
        return new SimpleValueChain(v, d, p);
    }
}

/**
 * ValueChain with actual path under which it is stored. Used when 
 * $(D_PSYMBOL resolve)ing instead of $(D_PSYMBOL get)ing values, allows
 * to inspect not only the value obtained from resolution, but also its
 * origins.
 */
alias ValueChainWithCoordinates(Data) = Tuple!(ValueChain!Data, "valueChain", Path, "realPath");

class PathTreeNode(Data) {
    alias Link = ValueChain!Data;
    alias LinkWithCoordinates = ValueChainWithCoordinates!Data;
    
    private Path fullPath;
    private PathTreeNode!Data[string] children;
    private Optional!(Link) valueChain = no!(Link); //todo rename to valueChain
    
    this(Path path){
        fullPath = path;
    }
    
    //
    // WRITE STACK
    // impl
    
    void put(Path path, Data data){
        //todo this introduces a silent feature - root can have value, paths can start and end with dots - cover that with tests! or check some conditions in public put
        if (path.empty){
            size_t nextVersion = (valueChain.empty ? -1 : valueChain.front().versionNo) + 1;
            auto prev = valueChain;
            Link newValueChain = Link.of(nextVersion, data.some, prev);
            valueChain = newValueChain.some;
        } else {
            if (!(path.head.front() in children)){
                auto childPath = this.fullPath.child(path.head.front());
                children[path.head.front()] = new PathTreeNode!Data(childPath);
            }
            children[path.head.front()].put(path.tail, data);
        }
    }
    
    Optional!Link getValueChain(Path path){
        if (path.empty){
            return valueChain;
        } else {
            return path.head.front() in children ? 
                    children[path.head.front()].getValueChain(path.tail) : 
                    no!Link;
        }
    }
    
    Optional!LinkWithCoordinates resolveValueChainWithCoordinates(Path path, Path upToRoot=Path.EMPTY){
        if (path.empty){
            return valueChain.map!(x => LinkWithCoordinates(x, fullPath)).toOptional;
        }
        auto deeperResult = path.head.front() in children ? 
                                children[path.head.front()].resolveValueChainWithCoordinates(path.tail, upToRoot) : 
                                no!LinkWithCoordinates;
        if (deeperResult.empty && fullPath.components.startsWith(upToRoot.components)){
            return valueChain.map!(x => LinkWithCoordinates(x, fullPath)).toOptional;
        }
        return deeperResult;
    }
}

alias PathMapper = Path delegate(Path); // viewPath -> backendPath
//toddo consider ValueMapper(T, T2) = T2 delegate(string, T); //(viewPath, backendValue) -> viewValue
alias ValueMapper(T, T2) = T2 delegate(T);


interface PathTreeView(Data){
    Optional!(ValueChain!Data) getValueChain(Path path);
    
    Optional!(ValueChain!Data) resolveValueChain(Path path, Path upToRoot=Path.EMPTY);
    
    /**
     * Returns: $(D_PSYMBOL some) over data stored under this exact $(D_PSYMBOL path); 
     * empty optional if no value was assigned.
     */
    final Optional!Data get(Path path) {
        return getValueChain(path).map!(x => x.data).joiner.toOptional;
    }
    
    /**
     * Returns: $(D_PSYMBOL some) over version number (counted from 0) of data 
     * stored under this exact $(D_PSYMBOL path); empty optional if no value was assigned.
     */
    final Optional!size_t getVersion(Path path) {
        return getValueChain(path).map!(x => x.versionNo).toOptional;
    }
    
    /**
     * Returns: $(D_PSYMBOL some) over data stored under this $(D_PSYMBOL path) or 
     * its closest ancestor; empty optional if no value was assigned anywhere 
     * from that node up to the root of the tree.
     */
    final Optional!Data resolve(Path path, Path upToRoot=Path.EMPTY) {
        return resolveValueChain(path, upToRoot).map!(x => x.data).joiner.toOptional;
    }
    
    final Optional!size_t resolveVersion(Path path, Path upToRoot=Path.EMPTY) {
        return resolveValueChain(path, upToRoot).map!(x => x.versionNo).toOptional;
    }
    
    final PathTreeView!Data subtree(Path from){
        assert(!from.empty);//todo exception
        return mapPaths((Path s) => from.join(s));
    }
    
    final PathTreeView!Data mapPaths(PathMapper mapper){
        class PathView: PathTreeView!Data {
            private PathTreeView!Data wrapped;
            private PathMapper foo;
            
            this(PathTreeView!Data wrapped, PathMapper foo){
                this.wrapped = wrapped;
                this.foo = foo;
            }
            
            Optional!(ValueChain!Data) getValueChain(Path path){
                return wrapped.getValueChain(foo(path));
            }
    
            Optional!(ValueChain!Data) resolveValueChain(Path path, Path upToRoot=Path.EMPTY){
                return wrapped.resolveValueChain(foo(path), foo(upToRoot));
            }
        }
        return new PathView(this, mapper);
    }
    
    final PathTreeView!NewData mapValues(NewData)(ValueMapper!(Data, NewData) mapper){
        alias Mapper = ValueMapper!(Data, NewData);
        
        class MappedLink: ValueChain!NewData {
            private ValueChain!Data wrapped;
            private Mapper foo;
            
            this(ValueChain!Data wrapped, Mapper foo){

                this.wrapped = wrapped;
                this.foo = foo;
            }
            
            @property
            size_t versionNo(){
                return wrapped.versionNo;
            }
            
            @property
            Optional!NewData data(){
                return wrapped.data.map!(x => foo(x)).toOptional;
            }
            
            @property
            Optional!(ValueChain!NewData) previousValue(){
                return wrapped.previousValue.map!(x => cast(ValueChain!NewData) new MappedLink(x, foo)).toOptional;
            }
        }
    
        class ValueView: PathTreeView!NewData {
            private PathTreeView!Data wrapped;
            private Mapper foo;
            
            this(PathTreeView!Data wrapped, Mapper foo){
                this.wrapped = wrapped;
                this.foo = foo;
            }
            
            Optional!(ValueChain!NewData) getValueChain(Path path){
                return wrapped.getValueChain(path)
                    .map!(x => cast(ValueChain!NewData) new MappedLink(x, foo))
                    .toOptional;
            }
    
            Optional!(ValueChain!NewData) resolveValueChain(Path path, Path upToRoot=Path.EMPTY){
                return wrapped.resolveValueChain(path, upToRoot)
                    .map!(x => cast(ValueChain!NewData) new MappedLink(x, foo))
                    .toOptional;
            }
        }
        return new ValueView(this, mapper);
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
    void put(Path path, Data data);
    
    Optional!LinkWithCoordinates resolveValueChainWithCoordinates(Path path, Path upToRoot=Path.EMPTY);
    
    final override Optional!Link resolveValueChain(Path path, Path upToRoot=Path.EMPTY) {
        return resolveValueChainWithCoordinates(path, upToRoot).map!(x => x.valueChain).toOptional;
    }
    
    /**
     * Returns: real path of the value that would be returned from 
     * $(D_PSYMBOL resolve(path)) wrapped into optional; empty if aforementioned 
     * call would result in empty optional.
     */
    final Optional!Path resolveCoordinates(Path path, Path upToRoot=Path.EMPTY) {
        return resolveValueChainWithCoordinates(path, upToRoot).map!(x => x.realPath).toOptional;
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
    private PathTreeNode!Data root = new PathTreeNode!Data(Path.EMPTY);
    
    override void put(Path path, Data data){
        root.put(path, data);
    }
    
    Optional!Link getValueChain(Path path) { //todo untested
        return root.getValueChain(path);
    }

    override Optional!LinkWithCoordinates resolveValueChainWithCoordinates(Path path, Path upToRoot=Path.EMPTY) { //todo untested
        return root.resolveValueChainWithCoordinates(path, upToRoot);
    }
    
}

//todo move to another source set
///basic usage
unittest {
    PathTree!string tree = new ConcretePathTree!string;

    tree.put(Path.parse("abc.def.g"), "x");
    tree.put(Path.parse("abc.def.g"), "y");

    assert(tree.get(Path.parse("abc.def.g")) == "y".some);
    assert(tree.getVersion(Path.parse("abc.def.g")) == 1.some);
    
    assert(tree.get(Path.parse("abc.def.g.h")) == no!string);
    assert(tree.getVersion(Path.parse("abc.def.g.h")) == no!size_t);
    
    assert(tree.resolve(Path.parse("abc.def.g.h")) == "y".some);
    assert(tree.resolveVersion(Path.parse("abc.def.g.h")) == 1.some);
    assert(tree.resolveCoordinates(Path.parse("abc.def.g.h")) == Path.parse("abc.def.g").some);
    
    auto mappedPaths = tree.subtree(Path.parse("abc"));
    assert(mappedPaths.get(Path.parse("def.g")) == "y".some);
    assert(mappedPaths.getVersion(Path.parse("def.g")) == 1.some);
    
    assert(mappedPaths.resolve(Path.parse("def.g.h")) == "y".some);
    assert(mappedPaths.resolveVersion(Path.parse("def.g.h")) == 1.some);
    
    mappedPaths = mappedPaths.subtree(Path.parse("def"));
    assert(mappedPaths.get(Path.parse("g")) == "y".some);
    assert(mappedPaths.getVersion(Path.parse("g")) == 1.some);
    
    assert(mappedPaths.resolve(Path.parse("g.h")) == "y".some);
    assert(mappedPaths.resolveVersion(Path.parse("g.h")) == 1.some);
    
    auto mappedKeys = mappedPaths.mapValues!size_t(x => x.length);
    assert(mappedKeys.get(Path.parse("g")) == 1.some);
    assert(mappedKeys.getVersion(Path.parse("g")) == 1.some);
    
    assert(mappedKeys.resolve(Path.parse("g.h")) == 1.some);
    assert(mappedKeys.resolveVersion(Path.parse("g.h")) == 1.some);
}
