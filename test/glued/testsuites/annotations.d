module glued.testsuites.annotations;

import std.meta;
import glued.annotations;

interface I {}
class C {}
struct St {}
enum E;   

unittest {
    with (Target.Type) {
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
    static assert(getExplicitAnnotations!A1 == AliasSeq!(X(), Y(), Z(1)));
    static assert(getExplicitAnnotations!A2 == AliasSeq!(X(), Y()));
    static assert(getExplicitAnnotations!A3 == AliasSeq!(X(), Y(), Z()));
}

@Target(Target.Type.STRUCT)
struct S {
    int x = 1;
}

@S
struct S1 {}

@Target(Target.Type.STRUCT)
@Implies!(S)
struct S2 {}

@Target(Target.Type.STRUCT)
@Implies!(S(2))
struct S3 {}

@Target(Target.Type.STRUCT)
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
