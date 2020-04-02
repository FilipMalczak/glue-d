module ex1.scan_aggregates;

import glued.stereotypes;

@Tracked
class X {
}

@Stereotype
struct Ster {

}

@Ster
class Y {}

@Ster @Component
class Z {}

//fixme what the hell? if its here, its alright, if its in the other module, it fails oO
//see: ./enum_.d
//enum NonTrackedBecauseEnum;

struct NonTrackedStruct {}
