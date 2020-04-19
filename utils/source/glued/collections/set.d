module glued.collections.set;

import std.range;

//todo WTF
//import glued.utils: isRangeOf;
enum isRangeOf(R, T) = isInputRange!T && is(ReturnType!((R r) => r.front()): T);


struct Set(T) {
    import std.algorithm;
    private T[] backend;
    
    static if (!isInputRange!T) {
        this(T data){
            add(data);
        }
    }
    
    this(T[] data){
        add(data);
    }
    
    this(V)(V data) if (isRangeOf!(V, T)|| is(V == T[])) {
        add(data);
    }
    
    void add(Set!T another){
        add(another.backend);
    }
    
    void add(T[] elem...){
        if (!backend.canFind(elem))
            backend ~= (elem);
        backend.sort;
    }
    
    void add(V)(V values) if (isRangeOf!(V, T)|| is(V == T[])){
        foreach (v; values){
            if (!backend.canFind(v))
                backend ~= (v);
        }
        backend.sort;
    }
    
    bool contains(T lookedUp){
        return backend.canFind(lookedUp);
    }
    
    @property
    size_t length(){
        return backend.length;
    }
    
    bool remove(T toRemove){
        T[] newBackend;
        scope (exit) backend = newBackend; 
        foreach (i, t; backend) {
            if (t != toRemove){
                newBackend ~= t;
            } else {
                newBackend ~= backend[i+1..$];
                return true;
            }
        }
        return false;
    }
    
    bool contains(T elem){
        return backend.canFind(elem);
    }
    
    //functional
    typeof(this) union_(typeof(this) another){
        auto result = this.length > another.length ? this : another;
        auto shorter = this.length > another.length ? another : this;
        result.add(shorter);
        return result;
    }
    
    auto union_(V)(V another) if (__traits(compiles, typeof(this)(another))){
        return this ~ typeof(this)(another);
    }
    
    typeof(this) intersection(typeof(this) another){
        T[] common;
        auto smaller = length < another.length ? this : another;
        auto theOther = length < another.length ? another : this;
        foreach (v; smaller)
            if (theOther.canFind(v)){
                common ~= v;
            }
        return typeof(this)(common);
    }
    
    // Set!int s;
    // s = [1, 2, 3, 2];
    void opAssign(V)(V data) if (isRangeOf!(V, T)){
        backend = [];
        add(data);
    }
    
    //S!T s; s[] -> T[]
    T[] opIndex(){
        return toArray();
    }

    //S!T s; s ~= t;
    void opOpAssign(string op)(T elem) if (op == "~") {
        add(elem);
    }
    
    //S!T s; s ~= [t1, t2];
    void opOpAssign(string op, V)(V data) if (op == "~" && isRangeOf!(V, T)) {
        add(data);
    }
    
    // s1 ~ s2 <=> s1 | s2 <=> s1.union_(s2)
    auto opBinary(string op, V)(V another) if (op == "|" || op == "~") {
        return union_(another);
    }
    
    // s1 & s2 <=> s1.intersection(s2)
    auto opBinary(string op, V)(V another) if (op == "&") {
        return union_(another);
    }
    
    // t in s
    bool opBinaryRight(string op)(T elem) if (op == "in") {
        return contains(elem);
    }
    
    //casting to list
    T[] opCast(U)() if (is (U == T[])) {
        return backend;
    }
    
    //InputRange
    @property
    bool empty(){
        return backend.empty;
    }
    
    @property
    T front(){
        return backend[0];
    }
    
    void popFront(){
        backend = backend[1..$];
    }
    
    //ForwardRange
    Set!T save() {
        return this;
    }
    
    string toString(){
        import std.traits;
        import std.conv;
        return "Set!("~fullyQualifiedName!T~")(backend="~to!string(backend)~")";
    }
    
    @property
    T[] array(){
        return backend;
    }
    
    T[] toArray(){
        return backend;
    }
}

unittest {
    static assert(isInputRange!(Set!int));
    static assert(isForwardRange!(Set!int));
    static assert(isRangeOf!(Set!int, int));
    
    Set!int s1 = [1, 2, 3, 2];
    assert(s1.toArray == [1, 2, 3]);
    Set!int s2 = [1, 2, 2, 3, 3];
    assert(s1 == s2);
    foreach (i, x; s1)
        assert(x == i+1);
    assert(!s1.empty);
    s1 = [];
    assert(s1.empty);
    
    s1 ~= [2, 2, 4];
    assert(s1 == Set([4, 2]));
    
    assert(Set([1, 2, 2, 5]).union_(Set([2, 5, 4, 1, 3, 9])) == Set([1, 2, 3, 4, 5, 9]));
    assert(Set([1, 2, 2, 7]).intersection(Set([2, 5, 4, 1, 3, 9])) == Set([1, 2]));
    
    assert((Set([1, 2, 2, 5]) | Set([2, 5, 4, 1, 3, 9])) == Set([1, 2, 3, 4, 5, 9]));
    assert((Set([1, 2, 2, 7]) & Set([2, 5, 4, 1, 3, 9])) == Set([1, 2]));
}
