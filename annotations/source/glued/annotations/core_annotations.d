/**
 * These are core annotations for the whole framework. To avoid recursive checks,
 * they are not annotated with constraints, but supported usage is documented 
 * with annotations in doc comments.
 */
module glued.annotations.core_annotations;

import std.meta: Alias;
import std.traits: hasUDA;

/**
 * This is core facility of annotation validation, so it won't be checked itself,
 * and won't have any annotations. If it would be annotated, UDAs would look like
 *     @OnAnnotation
 *     @Repeatable(ANY_NUMBER)
 *     @NonImplicable
 * todo this is already outdated
 * @param Checker - bool foo(alias target, alias annotation, alias constraint)()
 *                  e.g. foo(UserController, Controller(), Target(CLASS)) - notice 
 *                      that target is symbol, while annotation and its constraint
 *                      are values
 */
struct CheckedBy(alias Checker){
    alias Check = Checker;
    
    static bool check(T...)(){
        return Checker!(T)();
    }
}

/**
 * If this annotation is present on another annotation, the annotated one cannot
 * be subject of Implies!(...).
 */
struct NonImplicable {}

//todo this can be easily replaced with inner aliases...
//todo disable constructors
struct Implies(S) if (is(S == struct)) { //todo if isAnnotation?
    static assert(!hasUDA!(S, NonImplicable), "Annotation "~fullyQualifiedName!S~" is not implicable and as such cannot be used in Implies!(...)");
    const S implicated = S.init;
    
    template getImplicated(){
        alias getImplicated = Alias!(S.init);
    }
}

struct Implies(alias S) if (is(typeof(S) == struct)) { //todo ditto
    static assert(!hasUDA!(typeof(S), NonImplicable), "Annotation "~fullyQualifiedName!(typeof(S))~" is not implicable and as such cannot be used in Implies!(...)");
    const typeof(S) implicated = S; 
     
    template getImplicated(){ 
        alias getImplicated = Alias!(S); 
    } 
}

//todo sanitize these; maybe some documentational UDA?

///UDA for "magic annotations" like OnParameter, that should be filtered out
/// when retrieving target annotations
//todo Implies is magic, checkedby and nonimplicable as well
enum GluedMagic;

//@Repeatable
//@Target(TargetType.FUNCTION)
@GluedMagic
struct OnParameter(size_t _paramIdx, alias _annotation)
{
    enum paramIdx = _paramIdx;
    alias annotation = _annotation;
}
