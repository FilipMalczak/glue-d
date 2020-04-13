module glued.annotations;

import std.conv;
import std.traits;
import std.meta;

import glued.utils;

//todo introduce RAW_STRUCT and friends, TEMPLATE, and then STRUCT = RAW_STRUCT | TEMPLATE
enum TargetType {
    MODULE = 0, //non-target 
    FUNCTION = 1<<0,
    VARIABLE = 1<<1,
    INTERFACE = 1<<2,
    CLASS = 1<<3,
    STRUCT = 1<<4,
    ENUM = 1<<5,
    //todo annotation?
    
    CODE = (FUNCTION | VARIABLE),
    
    DATA = (STRUCT | ENUM),
    POINTER = (INTERFACE | CLASS),
    TYPE = (DATA | POINTER),
    
    ANY = (CODE | TYPE)
}

mixin template TargetTypeAnnotationBody() {
    TargetType[] types;
    int mask;
    
    this(TargetType[] types...){
        assert(types.length); //todo
        this.types = types;
        foreach (TargetType type; types)
            mask = mask | type;
    }
    
    /**
     * @param checked - type of element that annotation (annotated with this Target) was put on
     * @return - if the annotation annotated with Target can be put on checked type of element
     */
    bool canAnnotate(TargetType checked){
        return (mask & to!int(checked)) > 0;
    }
}


/**
 * This is core facility of annotation validation, so it won't be checked itself,
 * and won't have any annotations. If it would be annotated, UDAs would look like
 *     @OnAnnotation()
 *     @Repeatable(ANY_NUMBER)
 * todo this is already outdated
 * @param Checker - template that evaluates to enum of type bool; it should take
 *                  single parameter, which would be annotated target. Result of
 *                  its evaluation will be subject to static assertion when 
 *                  retrieving parameters annotations, so don't use this module
 */
struct CheckedBy(alias Checker){
    alias Check = Checker;
    
    static bool check(T...)(){
        return Checker!(T)();
    }
}

bool TargetChecker(alias target, alias annotation, alias constraint)(){
    return constraint.canAnnotate(TargetTypeOf!(target));
}

bool TargetOwnerChecker(alias target, alias annotation, alias constraint)(){
    return constraint.canAnnotate(TargetTypeOf!(__traits(parent, target)));
}

@OnAnnotation
@CheckedBy!(TargetChecker)
struct Target {
    mixin TargetTypeAnnotationBody;
}

@CheckedBy!(TargetOwnerChecker)
@OnAnnotation
struct TargetOwner {
    mixin TargetTypeAnnotationBody;
}

@Target(TargetType.CODE)
@TargetOwner(TargetType.TYPE)
struct OnStatic {}

@Target(TargetType.STRUCT)
struct OnAnnotation {}
alias Metaannotation = OnAnnotation;

template TargetTypeOf(T...) if (T.length == 1) {
    static if (is(T[0])) {
        static if (is(T[0] == class)){
            enum TargetTypeOf = TargetType.CLASS;
        } 
        else
        static if (is(T[0] == interface)){
            enum TargetTypeOf = TargetType.INTERFACE;
        }
        else
        static if (is(T[0] == struct)){
            enum TargetTypeOf = TargetType.STRUCT;
        }
        static if (is(T[0] == enum)){
            enum TargetTypeOf = TargetType.ENUM;
        }
    } else {
        //todo what about templates? template ... { class ... }}
        static assert(false, "support for methods and fields is coming");
    }
}

//todo this can be easily replaced with inner aliases...
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

//todo wrong name
enum onlyStructs(alias X) = is (typeof(X) == struct);

template expandToData(alias X){
    static if (__traits(isTemplate, X)){
        static if (__traits(compiles, X!())) {
            alias templateInstance = X!();
        } else {
            static if (__traits(compiles, X!(void))){
                alias templateInstance = X!(void);
            } else {
                pragma(msg, "CANNOT EXPAND ", X, " WITH DEFAULTS, SKIPPING");
                alias templateInstance = void;
            }
        }
        static if (is(templateInstance == void)){
            enum expandToData;
        } else {
            enum expandToData = expandToData!(templateInstance);
        }
    } else {
        static if (is(X)){
            static if (is(X == struct)) {
                enum expandToData = X.init;
            } else {
                enum expandToData;
            }
        } else {
            enum expandToData = X;
        }
    }
}

template getExplicitAnnotations(alias M) {
    alias getExplicitAnnotations = Filter!(onlyStructs, staticMap!(expandToData, __traits(getAttributes, M)));
}

template getExplicitAnnotationTypes(alias M) {
    alias getRawType(alias T) = typeof(T);
    alias getExplicitAnnotationTypes= NoDuplicates!(staticMap!(toType, getExplicitAnnotations!M), staticMap!(getRawType, getExplicitAnnotations!M));
}

template getImplicitAnnotations(alias M) {
    template toTypes(X...) {
        alias toTypes = staticMap!(toType, X);
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
            //todo what a clustertruck
            alias theirImplications = step!(0);//staticMap!(extractImplicit, toTypes!theirImplications);//probably extract from all UDAs instead
            alias extractImplicit = AliasSeq!(locallyImplicated, theirImplications);
        }
        else 
        {
            alias extractImplicit = locallyImplicated;
        }
    }
    
    alias getImplicitAnnotations = staticMap!(extractImplicit, getExplicitAnnotationTypes!M);
}

alias getUncheckedAnnotations(alias M) = AliasSeq!(NoDuplicates!(AliasSeq!(getExplicitAnnotations!M, getImplicitAnnotations!M)));

template performCheck(alias AnnotatedTarget){ // e.g. newly declared interface
    template getCheckers(alias constraint){
        alias getCheckers = staticMap!(expandToData, getUDAs!(typeof(constraint), CheckedBy));
    }

    template on(alias AnnotationOccurence){ //e.g. Component() (notice that it's value, not type)
        alias constraints = getExplicitAnnotations!(typeof(AnnotationOccurence)); // e.g. Repeatable(ONCE) (ditto); todo: maybe checked?
        static foreach (constraint; constraints){ // Repeatable(...) annotated with CheckedBy!(...)
            static foreach (checker; getCheckers!(constraint)){
                import std.conv;
                import std.traits;
                //todo message should be configurable next to CheckedBy
                static assert(checker.check!(AnnotatedTarget, AnnotationOccurence, constraint)(), "Constraint "~to!string(constraint)~" for annotation "~to!string(AnnotationOccurence)~" on target "~fullyQualifiedName!(AnnotatedTarget));
            }
        }
        alias on = AnnotationOccurence;
    }
}

alias getAnnotations(alias M) = AliasSeq!(staticMap!(performCheck!M.on, getUncheckedAnnotations!M));

template getAnnotations(alias M, alias T) {
    import glued.utils: ofType;
    alias pred = ofType!T;
    alias getAnnotations = Filter!(pred, getAnnotations!M);
}

template getAnnotation(alias M, alias T) {
    import glued.utils: ofType;
    //todo return None instead? allow ommiting by version?
    static assert(hasOneAnnotation!(M, T));
    enum getAnnotation = getAnnotations!(M, T)[0];
}

enum hasOneAnnotation(alias M, alias T) = getAnnotations!(M, T).length == 1;

enum hasAnnotation(alias M, alias T) = getAnnotations!(M, T).length > 0;
