module glued.annotations.common_annotations;

import std.conv: to;

import glued.annotations.core_annotations;
import glued.annotations.common_impl;

private mixin template TargetTypeAnnotationBody() {
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

enum OnAnnotation = Target(TargetType(TargetType.STRUCT));
alias Metaannotation = OnAnnotation;


