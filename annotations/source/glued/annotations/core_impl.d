module glued.annotations.core_impl;

import std.meta: AliasSeq, Filter, staticMap, NoDuplicates;
import std.traits: getUDAs;

import glued.annotations.core_annotations;
import glued.annotations.validation_impl;
import glued.utils: ofType, toType;

//todo wrong name
enum isStructInstance(alias X) = is (typeof(X) == struct);

template expandToData(alias X)
    {
    static if (__traits(isTemplate, X))
    {
        static if (__traits(compiles, X!())) 
        {
            alias templateInstance = X!();
        } 
        else 
        {
            static if (__traits(compiles, X!(void)))
            {
                alias templateInstance = X!(void);
            } 
            else 
            {
                pragma(msg, "CANNOT EXPAND ", X, " WITH DEFAULTS, SKIPPING");
                alias templateInstance = void;
            }
        }
        static if (is(templateInstance == void))
        {
            enum expandToData;
        } 
        else 
        {
            enum expandToData = expandToData!(templateInstance);
        }
    } 
    else 
    {
        static if (is(X))
        {
            static if (is(X == struct)) 
            {
                enum expandToData = X.init;
            } 
            else 
            {
                enum expandToData;
            }
        } 
        else 
        {
            enum expandToData = X;
        }
    }
}

template getExplicitAnnotations(alias M) 
{
    alias getExplicitAnnotations = Filter!(isStructInstance, staticMap!(expandToData, __traits(getAttributes, M)));
}

template getExplicitAnnotationTypes(alias M) 
{
    alias getRawType(alias T) = typeof(T);
    alias getExplicitAnnotationTypes= NoDuplicates!(staticMap!(toType, getExplicitAnnotations!M), staticMap!(getRawType, getExplicitAnnotations!M));
}

template toTypes(X...) 
{
    alias toTypes = staticMap!(toType, X);
}

template extractImplicit(alias A) 
{
//correct way: check what not-Implies!(...) annotations imply, extract Implies from these
//add local Implies, profit
//todo
//        static assert isAnnotation!A;
    alias unpack(I) = I.getImplicated!(); 
    alias implications = getUDAs!(A, Implies); 
    alias locallyImplicated = staticMap!(unpack, implications); 
    static if (locallyImplicated.length > 0) 
    {
        template step(int i, Acc...)
        {
            static if (i == locallyImplicated.length)
            {
                alias step = Acc;
            }
            else 
            {
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

template getImplicitAnnotations(alias M) 
{
    alias getImplicitAnnotations = staticMap!(extractImplicit, getExplicitAnnotationTypes!M);
}

alias getUncheckedAnnotations(alias M) = AliasSeq!(NoDuplicates!(AliasSeq!(getExplicitAnnotations!M, getImplicitAnnotations!M)));

alias getAnnotations(alias M) = AliasSeq!(staticMap!(performCheck!M.on, getUncheckedAnnotations!M));

template getAnnotations(alias M, alias T) 
{
    alias pred = ofType!T;
    alias getAnnotations = Filter!(pred, getAnnotations!M);
}

template getAnnotation(alias M, alias T) 
{
    //todo return None instead? allow ommiting by version?
    static assert(hasOneAnnotation!(M, T));
    enum getAnnotation = getAnnotations!(M, T)[0];
}

enum hasOneAnnotation(alias M, alias T) = getAnnotations!(M, T).length == 1;

enum hasAnnotation(alias M, alias T) = getAnnotations!(M, T).length > 0;
