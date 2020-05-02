module ex1.scan_aggregates;

class C {
}

interface I {}

class C2: I {}

enum ThisShallGetIgnored;
enum ThisAsWell: int;
//see comments in glued.codescan.unrollscan.scanModule

enum JustEnum { A, B }

enum StringEnum {X ="x"}

struct Struct {}
