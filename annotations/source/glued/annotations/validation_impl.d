module glued.annotations.validation_impl;

import std.meta: staticMap;
import std.traits: getUDAs;

import glued.annotations.core_impl: getExplicitAnnotations, expandToData;
import glued.annotations.core_annotations: CheckedBy;

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
