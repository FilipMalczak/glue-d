module glued.application.stereotypes;

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

/**
 * "is S marked as an annotation indicating something being of a stereotype?"
 * true for things like Component, Controller, etc
 */
enum isStereotype(S) = (is(S == struct) && hasAnnotation!(S, Stereotype));
enum isStereotype(alias S) = (is(typeof(S) == struct) && hasAnnotation!(typeof(S), Stereotype));

alias getStereotypes(alias M) = Filter!(isStereotype, getAnnotations!M);

template getStereotype(alias M, S) {
    alias found = AliasSeq!(Filter!(ofType!S, getStereotypes!M));
//    static assert(found.length == 1); //todo getStereotypes(M, S) and enable this check? or < 2
    enum getStereotype = found;
};

/**
 * "is M marked as being of stereotype S?"
 * true for example for M=UserController and S=Controller
 */ 
enum isMarkedAsStereotype(alias M, S) = getStereotype!(M, S).length > 0;
