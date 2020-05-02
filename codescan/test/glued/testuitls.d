module glued.testutils;

import std.traits;

struct Pair {
    string mod;
    string name;
}

Pair toPair(alias T)() if (is(T)){
    return Pair(moduleName!(T), T.stringof);
}
