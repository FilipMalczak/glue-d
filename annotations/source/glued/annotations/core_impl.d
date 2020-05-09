module glued.annotations.core_impl;

import std.meta: AliasSeq, Filter, staticMap, NoDuplicates, allSatisfy;
import std.traits;

import glued.annotations.core_annotations;
import glued.annotations.validation_impl;
import glued.utils: ofType, toType, toAnnotableType;

private struct ParameterPointer(alias Foo){
    alias Target = Foo;
    string paramName;
    size_t paramIdx;
}

template parameter(alias Foo, size_t paramIdx)
    if (isCallable!(Foo) && paramIdx < Parameters!Foo.length)
{
    enum parameter = ParameterPointer!(Foo)(ParameterIdentifierTuple!(Foo)[paramIdx], paramIdx);
}

enum isStructInstance(alias X) = is (typeof(X) == struct);

template isNotMagic(X...)
    if (X.length == 1)
{
    enum nonMagicalType(X) = !hasUDA!(X, GluedMagic);
    static if (is(X))
    {
        enum isNotMagic = nonMagicalType!X;
    }
    else
    {
        enum isNotMagic = allSatisfy!(nonMagicalType, toAnnotableType!(X));    
    }
}

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
    enum isParamPointer(alias X) = __traits(hasMember, X, "Target") &&
                                    __traits(hasMember, X, "paramName") &&
                                    __traits(hasMember, X, "paramIdx"); //todo check types of these fields
    static if (isParamPointer!M)
    {
        //todo clean up these debug "logs" (check "functions" testsuite too)
//        pragma(msg, __FILE__, ":", __LINE__);
        
        alias OnParameterUDAs = staticMap!(expandToData, getUDAs!(M.Target, OnParameter));
//        pragma(msg, "PARAM UDA ", M.stringof, " -> ", OnParameterUDAs);
        
        enum pred(alias U) = U.paramIdx == M.paramIdx;
        alias relevant = Filter!(pred, OnParameterUDAs);
//        pragma(msg, "PARAM RELEVANT ", M.stringof, " -> ", relevant);
        
        enum unpack(alias X) = expandToData!(X.annotation);
        alias getExplicitAnnotations = staticMap!(unpack, relevant);
//        pragma(msg, "PARAM RESULT ", M.stringof, " -> ", getExplicitAnnotations);
    }
    else
    {
        enum pred(alias X) = isStructInstance!X && isNotMagic!X;
        alias getExplicitAnnotations = Filter!(pred, staticMap!(expandToData, __traits(getAttributes, M)));
    }
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
//there may be some weird bug here, I suppose it will come up at some point
//correct way: check what not-Implies!(...) annotations imply, extract Implies from these
//add local Implies, profit
    alias unpack(I) = I.getImplicated!(); 
    alias implications = getUDAs!(A, Implies); 
    alias locallyImplicated = staticMap!(unpack, implications); 
    static if (locallyImplicated.length > 0) 
    {
        template step(size_t i, Acc...)
        {
            static if (i == locallyImplicated.length)
            {
                alias step = Acc;
            }
            else 
            {
                alias types = toAnnotableType!(locallyImplicated[i]);
                template innerStep(size_t j, Acc2...)
                {
                    static if (j == types.length)
                    {
                        alias innerStep = Acc2;
                    }
                    else
                    {
                        alias innerStep = innerStep!(j+1, AliasSeq!(extractImplicit!(types[j]), Acc2));
                    }
                }
                alias step = step!(i+1, AliasSeq!(innerStep!0, Acc));
            }
        }
        //I've had at least 4 distinct approaches to proper staticMap-based 
        //solution to this
        //if you gave up on life and just want to waste as much time as possible
        //before sweet death takes you away, have a go
        //
        //PS. tell "resursive template expansion" that I've said 'hi, I still hate you'
        alias theirImplications = step!(0);
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
    static assert(hasOneAnnotation!(M, T));
    enum getAnnotation = getAnnotations!(M, T)[0];
}

enum hasOneAnnotation(alias M, alias T) = getAnnotations!(M, T).length == 1;

enum hasAnnotation(alias M, alias T) = getAnnotations!(M, T).length > 0;
