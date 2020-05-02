module ex1.scan_aggregates;

import glued.application.stereotypes;

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


enum IgnoredEnum;

enum AnotherIgnored: int;

enum NonTrackedEnum { X, Y }

@Tracked
enum TrackedEnum {YAY}

struct NonTrackedStruct {}
