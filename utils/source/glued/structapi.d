module glued.structapi;

import std.traits;
import std.meta;

template satisfies(S, I) if (is(S == struct) && is(I == interface)){
    template structHasMethod(string name, int interfaceOverloadIdx){
        static if (!__traits(hasMember, S, name))
            enum structHasMethod = false;
        else static if (!isCallable!(__traits(getMember, S, name))){
            enum structHasMethod = false;
        } else {
            alias interfaceParams = Parameters!(__traits(getOverloads, I, name)[interfaceOverloadIdx]);
            template anyStructOverloadMatches(int i=0){
                static if (i < __traits(getOverloads, S, name).length) {
                    alias structParams = Parameters!(__traits(getOverloads, S, name)[i]);
                    enum anyStructOverloadMatches = is(structParams == interfaceParams) || anyStructOverloadMatches!(i+1);
                } else {
                    enum anyStructOverloadMatches = false;
                }
            }
            enum structHasMethod = anyStructOverloadMatches!();
        }
    }
    
    template allInterfaceMethodsInStruct(int i=0){
        //todo no support for final and private (? does D have those) methods yet
        static if (i<__traits(allMembers, I).length){
            enum name = __traits(allMembers, I)[i];
            template allOverloadsInStruct(int j=0){
                static if (j<__traits(getOverloads, I, name).length){
                    enum allOverloadsInStruct = structHasMethod!(name, j) && allOverloadsInStruct!(j+1);
                } else {
                    enum allOverloadsInStruct = true;
                }
            }
            enum allInterfaceMethodsInStruct = allOverloadsInStruct!();
        } else {
            enum allInterfaceMethodsInStruct = true;
        }
    }
    
    enum satisfies = allInterfaceMethodsInStruct!();
}

version(unittest){
    interface I {
        void foo();
        void foo(int i);
        
        string bar();
    }
    
    struct S1 {
        void foo() {}
        void foo(int i){}
        string bar(){return "";}
    }
    
    struct S2 {
        void foo() {}
        string bar(){return "";}
    }
//todo this should satisfy the interface, but it doesn't...
//    struct S3 {
//        void foo(int i=0) {}
//        string bar(){return "";}
//    }
}

unittest {
    static assert(satisfies!(S1, I));
    static assert(!satisfies!(S2, I));
//    static assert(satisfies!(S3, I));
}
