module glued.collections.reference;

import std.range;
import std.traits;

class Reference(T) {
    T val;
    
    this(T val){
        this.val = val;
    }

    @property
    ref T target(){
        return val;
    }
}

Reference!T reference(T)(T t){
    return new Reference!T(t);
}

Reference!U castDown(U, T)(Reference!T r){
    return reference(cast(U) r.target);
}

Reference!(U[]) castArrayDown(U, T)(Reference!(T[]) r){
    U[] result;
    foreach (t; r.target){
        result ~= cast(U) t;
    }
    return reference(result);
}

version (unittest) {
    struct X {
        int x;

        void foo(){
            x += 1;
        }
    }

    class C1 {}

    class C2: C1 {}
}

unittest {
    X x = X();
    x.x = 3;
    x.foo();
    assert(x.x == 4);
    Reference!X x2;
    x2 = new Reference!X(x);
    assert(x2.target.x == 4);
    x2.target.foo();
    assert(x.x == 4);
    assert(x2.target.x == 5);
    X x3 = x2.target;
    assert(x3.x == 5);
    x3.foo();
    assert(x3.x == 6);
    assert(x2.target.x == 5);
    
    
    C2 c2 = new C2();
    Reference!C1 c1 = reference(c2).castDown!C1;
    
    C2[] c2arr;
    c2arr ~= new C2();
    Reference!(C1[]) c1arr = reference(c2arr).castArrayDown!C1;
    assert(c1arr.target.length == 1);
    assert(c1arr.target[0] is c2arr[0]);
}
