module glued.annotations.core_annotations;

import std.meta: Alias;

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
