module glued.collections.reference;

import std.range;
import std.traits;

class Reference(T) if (is(T == struct) || is(T == enum) || isArray!T || isAssociativeArray!T ) {
    T val;
    
    this(T val){
        this.val = val;
    }

    @property
    T target(){
        return val;
    }

    U castDown(U)(){
        static if (isArray!T && isArray!U ){
            alias TVal = ElementType!T;
            alias UVal = ElementType!U;
            TVal[] values = target;
            U result;
            foreach (v; values){
                UVal u = cast(UVal) v;
                if (u is null && v !is null) {
                    return cast(U) val;
                }
                result ~= u;
            }
            return result;
        } else {
            return cast(U) val;
        }
    }
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
    X x = new X();
    x.x = 3;
    x.foo();
    assert(x.x == 4);
    Reference!X x2;
    x2 = x;
    assert(x2.x == 4);
    x2.foo();
    assert(x.x == 4);
    assert(x2.x == 5);
    X x3 = x2;
    assert(x3.x == 5);
    x3.foo();
    assert(x3.x == 6);
    assert(x2.x == 5);
    
    
    C2 c2 = new C2();
    Reference!C1 c1 = c2;
    
    C2[] c2arr;
    c2arr ~= new C2();
    Reference!(C1[]) c1arr = c2arr;
    assert(c1arr.length == 1);
    assert(c1arr[0] is c2arr[0]);
}
