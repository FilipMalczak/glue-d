module glued.annotations;

import std.conv;
import std.traits;
import std.meta;

//todo Ive prepared all that while Im not sure its useful...

struct Target {
    enum Type {
        METHOD = 1<<0,
        FIELD = 1<<1,
        INTERFACE = 1<<2,
        CLASS = 1<<3,
        STRUCT = 1<<4,
        ENUM = 1<<5,
        //todo annotation?
        
        MEMBER = (METHOD | FIELD),
        
        DATA = (STRUCT | ENUM),
        POINTER = (INTERFACE | CLASS),
        TYPE = (DATA | POINTER),
        
        ANY = (MEMBER | TYPE)
    }

    Type[] types;
    int mask;
    
    this(Type[] types...){
        assert(types.length); //todo
        this.types = types;
        foreach (Type type; types)
            mask = mask | type;
    }
    
    /**
     * @param checked - type of element that annotation (annotated with this Target) was put on
     * @return - if the annotation annotated with Target can be put on checked type of element
     */
    bool canAnnotate(Type checked){
        return (mask & to!int(checked)) > 0;
    }
}

template TargetTypeOf(T...) if (T.length == 1) {
    static if (is(T[0])) {
        static if (is(T[0] == class)){
            enum TargetTypeOf = Target.Type.CLASS;
        } 
        else
        static if (is(T[0] == interface)){
            enum TargetTypeOf = Target.Type.INTERFACE;
        }
        else
        static if (is(T[0] == struct)){
            enum TargetTypeOf = Target.Type.STRUCT;
        }
        static if (is(T[0] == enum)){
            enum TargetTypeOf = Target.Type.ENUM;
        }
    } else {
        static assert(false, "support for methods and fields is coming");
    }
}

version(unittest) {
    interface I {}
    class C {}
    struct St {}
    enum E;   
}

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
//todo disable constructors
struct Implies(S) if (is(S == struct)) { //todo if isAnnotation?
    const S implicated = S.init;
    
    template getImplicated(){
        alias getImplicated = Alias!(S.init);
    }
}

struct Implies(alias S) if (is(typeof(S) == struct)) { //todo ditto
    const typeof(S) implicated = S;
    
    template getImplicated(){
        alias getImplicated = Alias!(S);
    }
}


enum onlyStructs(alias X) = is(X) ? is(X == struct) : is (typeof(X) == struct);

enum expandToData(alias X) = is(X) ? X.init : X;

template getType(alias X) if (!is(X)) {
    alias getType = typeof(X);
}

template getExplicitAnnotations(alias M) {
    alias getExplicitAnnotations = staticMap!(expandToData, Filter!(onlyStructs, __traits(getAttributes, M)));
}

template getExplicitAnnotationTypes(alias M) {
    alias getExplicitAnnotationTypes= staticMap!(getType, getExplicitAnnotations!M);
}

version(unittest) {
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
}

unittest {
    static assert(getExplicitAnnotations!A1 == AliasSeq!(X(), Y(), Z(1)));
    static assert(getExplicitAnnotations!A2 == AliasSeq!(X(), Y()));
    static assert(getExplicitAnnotations!A3 == AliasSeq!(X(), Y(), Z()));
}

template getImplicitAnnotations(alias M) {
    template toTypes(X...) {
        alias toType(alias X) = typeof(X);
        alias toTypes = staticMap!(toType, X);
    }
    
    template hackMe(alias X){
        alias hackMe = extractImplicit!X;
    }

    template extractImplicit(alias A) {
    //correct way: check what not-Implies!(...) annotations imply, extract Implies from these
    //add local Implies, profit
//todo
//        static assert isAnnotation!A;
        alias unpack(I) = I.getImplicated!();
        alias implications = getUDAs!(A, Implies);
        alias locallyImplicated = staticMap!(unpack, implications);
        static if (locallyImplicated.length > 0) 
        {
            template step(int i, Acc...){
                static if (i == locallyImplicated.length)
                    alias step = Acc;
                else {
                    alias step = step!(i+1, AliasSeq!(extractImplicit!(typeof(locallyImplicated[i])), Acc));
                }
            }
            alias theirImplications = step!(0);//staticMap!(extractImplicit, toTypes!theirImplications);//probably extract from all UDAs instead
            alias extractImplicit = AliasSeq!(locallyImplicated, theirImplications);
        }
        else 
        {
            alias extractImplicit = locallyImplicated;
        }
    }
    
    alias getImplicitAnnotations = staticMap!(extractImplicit, toTypes!(getExplicitAnnotations!M));
}

version(unittest) {
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
}

unittest {
    static assert(getImplicitAnnotations!(T1).length == 0);
    static assert(getImplicitAnnotations!(T2) == AliasSeq!(S(1)));
    static assert(getImplicitAnnotations!(T3) == AliasSeq!(S(2)));
    static assert(getImplicitAnnotations!(T4) == AliasSeq!(S2(), S(1)));
}

alias getAnnotations(alias M) = NoDuplicates!(AliasSeq!(getExplicitAnnotations!M, getImplicitAnnotations!M));

unittest {
    static assert(getAnnotations!(T1) == AliasSeq!(S1()));
    static assert(getAnnotations!(T2) == AliasSeq!(S2(), S()));
    static assert(getAnnotations!(T3) == AliasSeq!(S3(), S(2)));
    static assert(getAnnotations!(T4) == AliasSeq!(S4(), S2(), S()));
}

template getAnnotations(alias M, T) {
    import glued.utils: ofType;
    alias getAnnotations = Filter!(ofType!T, getAnnotations!M);
}

enum hasAnnotation(alias M, T) = getAnnotations!(M, T).length > 0;
/**
fixme this should work but doesnt

that happens because if something is not an Implies!(...), we don't follow it up to see if super-annotation has implications

version(unittest){
    @Implies!(Implies!Sticker)
    struct Sticker {}
    
    @Sticker
    struct Ann1 {}
    
    @Ann1
    struct Ann2 {}
    
    @Ann2
    struct Ann3 {}
    
    @Ann3
    struct Annotated {}
}

unittest {
    alias res = getAnnotations!Annotated;
    pragma(msg, "XXX", res);
}*/
