module glued.testutils;

interface FooWithExpected 
{
    int foo(int x);
    int expected(int x);
}

void compareResults(FooWithExpected f, int[] fixed, size_t toRandomize)
{
    import std.random;
    import core.exception;
    import std.stdio;
    import std.algorithm;
    
    int[] toCheck;
    toCheck ~= fixed;
    while (toCheck.length < (toRandomize+fixed.length))
    {
        int candidate = uniform!int;
        if (!toCheck.canFind(candidate))
            toCheck ~= candidate;
    }
    foreach (i; toCheck)
    {
        auto result = f.foo(i);
        auto expectedResult = f.expected(i);
        try
        {
            assert(result == expectedResult);
        } catch (AssertError e)
        {
            writeln("ERROR: Expected ", expectedResult, "; got ", result, " instead! (arg: ", i, ")");
            throw e;
        }
    }
}

