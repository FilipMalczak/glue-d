/**
 * These are core annotations for the whole framework. To avoid recursive checks,
 * they are not annotated with constraints, but supported usage is documented 
 * with annotations in doc comments.
 */
module glued.annotations.core_annotations;

import std.meta: Alias;
import std.traits: hasUDA;

import glued.annotations.common_annotations;
import glued.annotations.common_impl;

///UDA for "magic annotations" like OnParameter, that should be filtered out
/// when retrieving target annotations
enum GluedMagic;

///Strictly documentational UDA; totally ignored by a framework, but defines
/// how the "magic" annotation would be used.
@GluedMagic
enum MagicUsage(T...) = "And this is how we do it";

@GluedMagic
@MagicUsage!(OnAnnotation, Repeatable, NonImplicable)
struct CheckedBy(alias Checker)
{
    ///bool foo(alias target, alias annotation, alias constraint)()
    ///where target is a symbol and annotation and constraint are values (struct
    ///instances)
    alias Check = Checker;
    
    static bool check(T...)()
    {
        return Checker!(T)();
    }
}

/**
 * If this annotation is present on another annotation, the annotated one cannot
 * be subject of Implies!(...).
 */
 @GluedMagic
struct NonImplicable {}

@GluedMagic
struct Implies(S) 
    if (is(S == struct)) 
{
    static assert(!hasUDA!(S, NonImplicable), "Annotation "~fullyQualifiedName!S~" is not implicable and as such cannot be used in Implies!(...)");
    ///Annotation "brought" by the one annotated with Implies
    const S implicated = S.init;
    
    template getImplicated()
    {
        alias getImplicated = Alias!(S.init);
    }
}

@GluedMagic
struct Implies(alias S) 
    if (is(typeof(S) == struct)) 
{
    static assert(!hasUDA!(typeof(S), NonImplicable), "Annotation "~fullyQualifiedName!(typeof(S))~" is not implicable and as such cannot be used in Implies!(...)");
    
    ///ditto
    const typeof(S) implicated = S; 
     
    template getImplicated()
    { 
        alias getImplicated = Alias!(S); 
    } 
}

//todo actually figure out parameter annotations instead of using this weird 'pointers'
@GluedMagic
@MagicUsage!(Repeatable, Target(TargetType.FUNCTION))
struct OnParameter(size_t _paramIdx, alias _annotation)
{
    enum paramIdx = _paramIdx;
    alias annotation = _annotation;
    
    enum describesParam(string name, size_t idx) = (idx == paramIdx);
}

@GluedMagic
@MagicUsage!(Repeatable, Target(TargetType.FUNCTION))
struct OnParameter(string _paramName, alias _annotation)
{
    enum paramName = _paramName;
    alias annotation = _annotation;
    
    enum describesParam(string name, size_t idx) = (name == paramName);
}
