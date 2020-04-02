module glued.stereotypes;

import std.meta;

import glued.annotations;
import glued.utils;

struct Tracked {}

@Implies!Tracked
struct Stereotype {}

@Stereotype
@Implies!Stereotype
@Implies!Tracked
struct Component {}

enum isStereotype(S) = (is(S == struct) && hasAnnotation!(S, Stereotype));
enum isStereotype(alias S) = (is(typeof(S) == struct) && hasAnnotation!(typeof(S), Stereotype));

version(unittest){
    struct NonStereotype {}
    
    @Component
    struct SpecializedComponent {}
    
    @Component
    interface SomeComponent {}
    
    @SpecializedComponent
    interface ComplicatedComponent {}
}

unittest {
    static assert(isStereotype!Component);
    static assert(!isStereotype!NonStereotype);
    static assert(isStereotype!SpecializedComponent);
    static assert(!isStereotype!SomeComponent);
    static assert(!isStereotype!ComplicatedComponent);
}

alias getStereotypes(alias M) = Filter!(isStereotype, getAnnotations!M);

template getStereotype(alias M, S) {
    alias found = Filter!(ofType!S, getStereotypes!M);
    static assert(found.length < 2);
    static if (found.length) {
        enum getStereotype = found[0];
    } else {
        enum getStereotype = None();
    }
    
};

enum isMarkedAsStereotype(alias M, S) = (getStereotype!(M, S) != None());
