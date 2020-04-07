module glued.testsuites.stereotypes;

import glued.stereotypes;

struct NonStereotype {}

@Register
struct SpecializedRegister {}

@Register
interface SomeRegister {}

@SpecializedRegister
interface ComplicatedRegister {}

unittest {
    static assert(isStereotype!Register);
    static assert(!isStereotype!NonStereotype);
    static assert(isStereotype!SpecializedRegister);
    static assert(!isStereotype!SomeRegister);
    static assert(!isStereotype!ComplicatedRegister);
}

@Stereotype
struct Controller {}

@Controller
class UserController {}

unittest {
    static assert(isStereotype!Controller);
    static assert(isMarkedAsStereotype!(UserController, Controller));
}
