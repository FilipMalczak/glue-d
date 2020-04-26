//fixme fugly, wrong place
module glued.set;

import std.traits;
import std.conv;
import std.array;
import std.range;
import std.algorithm;

struct Set(T) {
    private bool[T] backend;
    
    bool put(T val){
        if (val in backend)
            return false;
        backend[val] = true;
        return true;
    }
    
    alias add = put;
    alias insert = put;
    
    size_t putMany(Range)(Range data){
        if (isInputRange!Range && is(ElementType!Range == T)) {
            size_t added = 0;
            foreach (t; data)
                if (put(t))
                    added += 1;
            return added;
        }
    }
    
    alias addMany = putMany;
    alias addAll = putMany;
    
    bool contains(T val){
        return (val in backend) != null;
    }
    
    bool remove(T val){
        return backend.remove(val);
    }
    
    @property
    size_t length(){
        return backend.length;
    }
    
    @property
    auto asRange(){
        return backend.keys()[];
    }
    
    Set!T2 asSetOf(T2)(){
        return Set!T2.of(asRange.map!(x => cast(T2) x));
    }
    
    //fixme this requires Set!T.of(...) - make Set.of!T(...) variant that is easily syntax-sugared to Set.of(...)
    static Set!T of(Range)(Range data) if (isInputRange!Range && is(ElementType!Range == T)) {
        Set!(T) result;
        result.addAll(data);
        return result;
    }
    
//    private static bool subTypeEquals(Super, Sub)(Set!Super superTypeSet, Set!Sub subTypeSet){
//        Set!Super castedSubTypeSet = Set!Super.of(subTypeSet.asRange.map!(x => cast(Super) x));
//        return superTypeSet == castedSubTypeSet;
//    }
//    
//    private template isAssignable(SuperCandidate, SubCandidate){
//        static if (is(SubCandidate: SuperCandidate)){
//            enum isAssignable = true;
//        } else
//        static if (is(SubCandidate == interface) && is (SuperCandidate == Object)){
//            enum isAssignable = true;
//        } else
//        enum isAssignable = false;
//    }
//    
//    bool genericEquals(T2)(Set!T2 other){
//        static if (isAssignable!(T2, T)) {
//            return this.asSetOf!T2 == other;
//        } else {
//            static if (isAssignable!(T, T2)){
//                return this == other.asSetOf!T;
////                return subTypeEquals!(T, T2)(this, other);
//            } else {
//                return false;
//            }
//        }
//    }
}
