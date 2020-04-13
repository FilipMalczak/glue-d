module glued.testsuites.annotations;

import std.meta;
import glued.annotations;

interface I {}
class C {}
struct St {}
enum E;   

unittest {
    import glued.annotations.common_impl;
    with (TargetType) {
        static assert(TargetTypeOf!I == INTERFACE);
        static assert(TargetTypeOf!C == CLASS);
        static assert(TargetTypeOf!St == STRUCT);
        static assert(TargetTypeOf!E == ENUM);
        
        static assert(Target(CLASS).canAnnotate(CLASS));
        static assert(Target(POINTER).canAnnotate(CLASS));
        static assert(Target(CLASS, STRUCT).canAnnotate(STRUCT));
        static assert(Target(CLASS, INTERFACE).canAnnotate(CLASS));
        static assert(Target(TYPE).canAnnotate(INTERFACE));
    }
}


struct X {
    int x=0;
}

struct Y {}

struct Z {
    int z;
}

@X @Y @Z(1)
struct A1{}

@X @Y @E
struct A2{}

@X @Y @Z
struct A3{}

unittest {
    import glued.annotations.core_impl;
    static assert(getExplicitAnnotations!A1 == AliasSeq!(X(), Y(), Z(1)));
    static assert(getExplicitAnnotations!A2 == AliasSeq!(X(), Y()));
    static assert(getExplicitAnnotations!A3 == AliasSeq!(X(), Y(), Z()));
}

@Target(TargetType.STRUCT)
struct S {
    int x = 1;
}

@S
struct S1 {}

@Target(TargetType.STRUCT)
@Implies!(S)
struct S2 {}

@Target(TargetType.STRUCT)
@Implies!(S(2))
struct S3 {}

@Target(TargetType.STRUCT)
@Implies!(S2)
struct S4 {}

@S1
struct T1 {}
@S2
struct T2 {}
@S3
struct T3 {}
@S4
struct T4 {}

unittest {
    import glued.annotations.core_impl;
    static assert(getImplicitAnnotations!(T1).length == 0);
    static assert(getImplicitAnnotations!(T2) == AliasSeq!(S(1)));
    static assert(getImplicitAnnotations!(T3) == AliasSeq!(S(2)));
    static assert(getImplicitAnnotations!(T4) == AliasSeq!(S2(), S(1)));
}

unittest {
    static assert(getAnnotations!(T1) == AliasSeq!(S1()));
    static assert(getAnnotations!(T2) == AliasSeq!(S2(), S()));
    static assert(getAnnotations!(T3) == AliasSeq!(S3(), S(2)));
    static assert(getAnnotations!(T4) == AliasSeq!(S4(), S2(), S()));
}

struct Generic(T) {
    alias Type = T;
}

@(Generic!(S1))
struct WithGeneric {}

unittest {
    static assert(getAnnotations!(WithGeneric) == AliasSeq!(Generic!S1()));
    static assert(getAnnotation!(WithGeneric, Generic!S1) == Generic!S1());
    static assert(getAnnotation!(WithGeneric, Generic) == Generic!S1());
    static assert(is(getAnnotation!(WithGeneric, Generic).Type == S1));
}

@Target(TargetType.CLASS)
struct AnnForClasses {}

@AnnForClasses
class ClassWithAnn {}

@AnnForClasses
struct ShouldFail {}

@OnAnnotation
struct MetaAnn {}

@MetaAnn
struct Ann {}

@MetaAnn
interface NonAnn {}

unittest {
    static assert(getAnnotations!(ClassWithAnn) == AliasSeq!(AnnForClasses()));
    static assert(!__traits(compiles, getAnnotations!(ShouldFail)));
    static assert(getAnnotations!(Ann) == AliasSeq!(MetaAnn()));
    static assert(!__traits(compiles, getAnnotations!(NonAnn)));
}

@NonImplicable
struct NonImpl {}

unittest {
    static assert(__traits(compiles, Implies!(Ann)));
    static assert(__traits(compiles, Implies!(Ann())));
    static assert(!__traits(compiles, Implies!(NonImpl)));
    static assert(!__traits(compiles, Implies!(NonImpl())));
}

@Repeatable(between(2, 4))
struct Repeated{
    int x;
}

@Repeated
struct NOK1 {}

@Repeated
@Repeated(0)
struct NOK1_duplicatedDefault {}

@Repeated
@Repeated(2)
struct OK2 {}

@Repeated
@Repeated(2)
@Repeated(3)
struct OK3 {}

@Repeated
@Repeated(0)
@Repeated(2)
@Repeated(3)
struct OK3_duplicateOf0 {}

@Repeated
@Repeated(2)
@Repeated(3)
@Repeated(4)
struct NOK4 {}

unittest {
    static assert(!__traits(compiles, getAnnotations!NOK1));
    static assert(!__traits(compiles, getAnnotations!NOK1_duplicatedDefault));
    static assert(getAnnotations!OK2 == AliasSeq!(Repeated(0), Repeated(2)));
    static assert(getAnnotations!OK3 == AliasSeq!(Repeated(0), Repeated(2), Repeated(3)));
    static assert(getAnnotations!OK3_duplicateOf0 == AliasSeq!(Repeated(0), Repeated(2), Repeated(3)));
    static assert(!__traits(compiles, getAnnotations!NOK4));
}
