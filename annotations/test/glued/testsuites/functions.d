module glued.testsuites.functions;

import std.meta;
import std.traits;
import std.algorithm;

import glued.annotations;

struct S1 { int x; }
struct S2 { int x; }

@Implies!(S1(7))
struct S3 { int x; }

@Implies!(S3(5))
struct S4 { int x; }

@OnParameter!(0, S1)
@OnParameter!(0, S2(3))
@OnParameter!(1, S3())
@OnParameter!("s", S4)
@OnParameter!("x", S2())
@S1
void foo(int x, string s, bool b){}


//todo annotation unittests assume ordering in asserts
//body contract doesn't specify the order, so this may lead to env-dependent tests
// and give an impression that tests fully define the contract

//todo test checkers(validation) on parameter annotations
unittest
{
    static assert(getAnnotations!(parameter!(foo, 0)) == AliasSeq!(S1(), S2(3), S2()));
    static assert(getAnnotations!(parameter!(foo, "x")) == AliasSeq!(S1(), S2(3), S2()));
    
    static assert(getAnnotations!(parameter!(foo, 1)) == AliasSeq!(S3(), S4(), S1(7), S3(5)));
    static assert(getAnnotations!(parameter!(foo, "s")) == AliasSeq!(S3(), S4(), S1(7), S3(5)));
    
    static assert(getAnnotations!(parameter!(foo, 2)).length == 0);
    static assert(getAnnotations!(parameter!(foo, "b")).length == 0);
    
    static assert(getAnnotations!(foo) == AliasSeq!(S1()));
}
