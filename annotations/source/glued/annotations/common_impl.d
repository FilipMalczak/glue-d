module glued.annotations.common_impl;

import std.traits;

import glued.utils;

enum TargetType {
    MODULE = 1 << 31, //non-target ; 31 is max value when using <<
    FUNCTION = 1<<0,
    VARIABLE = 1<<1,
    INTERFACE = 1<<2,
    CLASS = 1<<3,
    STRUCT = 1<<4,
    ENUM = 1<<5,
    //todo consider making annotations, templates, unittests targets as well; introduce RAW_STRUCT and friends, TEMPLATE, and then STRUCT = RAW_STRUCT | TEMPLATE
    
    CODE = (FUNCTION | VARIABLE),
    
    DATA = (STRUCT | ENUM),
    POINTER = (INTERFACE | CLASS),
    TYPE = (DATA | POINTER),
    
    ANY = (CODE | TYPE)
}

bool TargetChecker(alias target, alias annotation, alias constraint)(){
    return constraint.canAnnotate(TargetTypeOf!(target));
}

bool TargetOwnerChecker(alias target, alias annotation, alias constraint)(){
    return constraint.canAnnotate(TargetTypeOf!(__traits(parent, target)));
}

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
        static if (isFunction!(T[0]))
        {
            enum TargetTypeOf = TargetType.FUNCTION;
        }
        else
        {
            static if (__traits(compiles, typeof(T[0])))
            {
                enum TargetTypeOf = TargetType.VARIABLE;
            }
            else 
            {
                enum TargetTypeOf = TargetType.MODULE;
            }
        }
    }
}

bool RepeatableChecker(alias target, alias annotation, alias constraint)(){
    import glued.annotations.core_impl: getUncheckedAnnotations;
    import std.meta: Filter;
    
    immutable occurences = Filter!(ofType!(toType!(annotation)), getUncheckedAnnotations!(target)).length; 
    return constraint.boundaries.check(occurences);
}
