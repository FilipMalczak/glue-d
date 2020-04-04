module glued.testsuites.stereotypes;

import glued.stereotypes;

struct NonStereotype {}

@Component
struct SpecializedComponent {}

@Component
interface SomeComponent {}

@SpecializedComponent
interface ComplicatedComponent {}

unittest {
    static assert(isStereotype!Component);
    static assert(!isStereotype!NonStereotype);
    static assert(isStereotype!SpecializedComponent);
    static assert(!isStereotype!SomeComponent);
    static assert(!isStereotype!ComplicatedComponent);
}
