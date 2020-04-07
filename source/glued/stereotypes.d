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
struct Register {} //todo -> Registered

@Stereotype
@Implies!Stereotype
@Implies!Tracked
struct Configuration {}

//import poodinis.context: PoodinisRegister = Register;

//template isStereotype(S) if (is(S == PoodinisRegister)) {
//    enum isStereotype = true;
//}
//template isStereotype(alias S) if (is(typeof(S) == PoodinisRegister)) {
//    enum isStereotype = true;
//}

/**
 * "is S marked as an annotation indicating something being of a stereotype?"
 * true for things like Register, Controller, etc
 */
enum isStereotype(S) = (is(S == struct) && hasAnnotation!(S, Stereotype));
enum isStereotype(alias S) = (is(typeof(S) == struct) && hasAnnotation!(typeof(S), Stereotype));

//template getAnnotations(T) if (is(T == PoodinisRegister)) {
//    alias getAnnotations = AliasSeq!(Tracked());
//}
//template getAnnotations(alias T) if (is(T == PoodinisRegister)){
//    alias getAnnotations = AliasSeq!(Tracked());
//}

alias getStereotypes(alias M) = Filter!(isStereotype, getAnnotations!M);

template getStereotype(alias M, S) {
    alias found = AliasSeq!(Filter!(ofType!S, getStereotypes!M));
//    static assert(found.length == 1);
    enum getStereotype = found;
};

/**
 * "is M marked as being of stereotype S?"
 * true for example for M=UserController and S=Controller
 */ 
enum isMarkedAsStereotype(alias M, S) = getStereotype!(M, S).length > 0;
//enum isMarkedAsStereotype(alias M, S) = Filter!(ofType!S, getStereotypes!M).length > 0;
