//fixme reorganize this mess of modules, their names and tests
//body tests are badly organized (should be module-per-feature), main code as 
//well (rest of glue-d doesn't use underscores, amongst other issues)
module glued.annotations;

public import glued.annotations.core_annotations;
public import glued.annotations.common_annotations;
public import glued.annotations.common_impl: TargetTypeOf, TargetType;
public import glued.annotations.core_impl: getAnnotation, getAnnotations, hasOneAnnotation, hasAnnotation, parameter;
