module ex3.mod;

import glued.stereotypes;

interface I1 {}

interface I2 {}

interface I3 : I1 {}

interface I4: I3 {}

interface I5: I2 {}

@Component
class C1 {}

@Tracked
class C2: I2 {}

@Component
class C3 : C2 {}

@Component
class C4: C3, I4 {}

@Component
class C5: C3, I5 {}

unittest {
    import std.traits;
    //BaseTypeTuple and BaseClassesTuple are not really well defined in the docs,
    //so here's a little sanity check
    import std.meta;
    
    import glued.logging;
    mixin CreateLogger;
    Logger log = Logger(new StdoutSink);
    
    //basically, BaseTypeTuple shows whats in type declaration code 
    //   and Object in case of classes that don't explicitly inherit from 
    //   other classes
    //while BaseClassesTuple shows class hierarchy path to Object
    
    static assert(BaseTypeTuple!I1.length ==0);
    static assert(BaseTypeTuple!I2.length ==0);
    static assert(is(BaseTypeTuple!I3 == AliasSeq!(I1)));
    static assert(is(BaseTypeTuple!I4 == AliasSeq!(I3)));
    static assert(is(BaseTypeTuple!I5 == AliasSeq!(I2)));
    
    static assert(is(BaseTypeTuple!C1 == AliasSeq!(Object)));
    static assert(is(BaseClassesTuple!C1 == AliasSeq!(Object)));
    
    static assert(is(BaseTypeTuple!C2 == AliasSeq!(Object, I2)));
    static assert(is(BaseClassesTuple!C2 == AliasSeq!(Object)));
    
    static assert(is(BaseTypeTuple!C3 == AliasSeq!(C2)));
    static assert(is(BaseClassesTuple!C3 == AliasSeq!(C2, Object)));
    
    static assert(is(BaseTypeTuple!C4 == AliasSeq!(C3, I4)));
    static assert(is(BaseClassesTuple!C4 == AliasSeq!(C3, C2, Object)));
    
    static assert(is(BaseTypeTuple!C5 == AliasSeq!(C3, I5)));
    static assert(is(BaseClassesTuple!C5 == AliasSeq!(C3, C2, Object)));
    
    static foreach(T; AliasSeq!(I1, I2, I3, I4, I5, C1, C2, C3, C4, C5)){
        log.Info.Emit!(T.stringof);
        log.Info.Emit!("\t", fullyQualifiedName!T);
        log.Info.Emit!("\t    BaseTypeTuple: ", BaseTypeTuple!T);
        static if (is(T == class))
            log.Info.Emit!("\t BaseClassesTuple: ", BaseClassesTuple!T);
        else
            log.Info.Emit!("\t BaseClassesTuple: N/A");
    }
}
