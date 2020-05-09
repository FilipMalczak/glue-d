module glued.testsuites.functions;

import std.meta;

import glued.annotations;

struct S1 { int x; }
struct S2 { int x; }
struct S3 { int x; }
struct S4 { int x; }

@OnParameter!(0, S1)
@OnParameter!(0, S2(3))
@OnParameter!(1, S3())
//@OnParameter!("s", S4)
//@OnParameter!("x", S2())
void foo(int x, string s, bool b){}

unittest
{
//    pragma(msg, getAnnotations!(parameter!(foo, 0)));
    static assert(getAnnotations!(parameter!(foo, 0)) == AliasSeq!(S1(), S2(3)));
//    static assert(getAnnotations!(parameter!(foo, 0)) == AliasSeq!(S1(), S2(3), S2()));
}
