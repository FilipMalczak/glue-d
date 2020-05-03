module glued.testsuites.stereotypes;

import glued.application.stereotypes;

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

@Stereotype
struct Controller {}

@Controller
class UserController {}

unittest {
    static assert(isStereotype!Controller);
    static assert(isMarkedAsStereotype!(UserController, Controller));
}
