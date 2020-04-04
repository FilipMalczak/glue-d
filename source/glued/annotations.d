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

alias getAnnotations(alias M) = NoDuplicates!(AliasSeq!(getExplicitAnnotations!M, getImplicitAnnotations!M));

template getAnnotations(alias M, T) {
    import glued.utils: ofType;
    alias getAnnotations = Filter!(ofType!T, getAnnotations!M);
}

enum hasAnnotation(alias M, T) = getAnnotations!(M, T).length > 0;
