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

@OnAnnotation
@CheckedBy!(TargetOwnerChecker)
struct TargetOwner {
    mixin TargetTypeAnnotationBody;
}

//todo missing checker, TemplateOf cannot find CODE pieces yet
@Target(TargetType.CODE)
@TargetOwner(TargetType.TYPE)
struct OnStatic {}

enum OnAnnotation = Target(TargetType(TargetType.STRUCT));
alias Metaannotation = OnAnnotation;

struct RepetitionBoundaries {
    size_t lowerInc;
    size_t upperExc;
    
    //this() assert both are positive
    
    bool check(int occurences){
        return occurences >= lowerInc && occurences < upperExc;
    }
}

RepetitionBoundaries exactly(size_t i){
    return RepetitionBoundaries(i, i+1);
}

RepetitionBoundaries atLeast(size_t i){
    return RepetitionBoundaries(i, size_t.max); //todo infinity?
}

RepetitionBoundaries atMost(size_t i){
    return RepetitionBoundaries(0, i+1);
}

alias between = RepetitionBoundaries;

enum exactlyOnce = exactly(1);

enum atLeastOnce = atLeast(1);

enum atMostOnce = atMost(1);
alias optional = atMostOnce;

enum notAtAll = RepetitionBoundaries(0, 0);

enum anyNumber = RepetitionBoundaries(0, size_t.max);

@Metaannotation
@CheckedBy!(RepeatableChecker)
struct Repeatable {
    RepetitionBoundaries boundaries;
}
