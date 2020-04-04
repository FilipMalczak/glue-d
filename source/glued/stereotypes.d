module glued.stereotypes;

import std.meta;

public import glued.annotations;
import glued.utils;

struct Tracked {}

@Implies!Tracked
struct Stereotype {}

@Stereotype
@Implies!Stereotype
@Implies!Tracked
struct Component {}

@Stereotype
@Implies!Stereotype
@Implies!Tracked
struct Configuration {}

//import poodinis.context: PoodinisComponent = Component;

//template isStereotype(S) if (is(S == PoodinisComponent)) {
//    enum isStereotype = true;
//}
//template isStereotype(alias S) if (is(typeof(S) == PoodinisComponent)) {
//    enum isStereotype = true;
//}

enum isStereotype(S) = (is(S == struct) && hasAnnotation!(S, Stereotype));
enum isStereotype(alias S) = (is(typeof(S) == struct) && hasAnnotation!(typeof(S), Stereotype));

//template getAnnotations(T) if (is(T == PoodinisComponent)) {
//    alias getAnnotations = AliasSeq!(Tracked());
//}
//template getAnnotations(alias T) if (is(T == PoodinisComponent)){
//    alias getAnnotations = AliasSeq!(Tracked());
//}

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
