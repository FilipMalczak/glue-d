module glued.scan;

import std.stdio;
import std.conv;
import std.array;
import std.ascii;
import std.random;
import std.typecons;
import std.meta;
import std.traits;
import std.variant;
import std.range;
import std.algorithm;
import std.string;

//import witchcraft;
import glued.mirror;
import glued.context;

void scan(string root)(){
    mixin("static import "~root~"._index;");
    mixin("alias mod_ = "~root~"._index;");
    
    void scanModule(string name)(){
        mixin("static import "~name~";");
        mixin("alias mod_ = "~name~";");
        static foreach (alias mem; __traits(allMembers, mod_)){
            static if (__traits(compiles, __traits(getMember, mod_, mem))){
                static if (is(__traits(getMember, mod_, mem))){
                    pragma(msg, "scanned ",name, " ", mem);
                    BackboneContext.get().track!(name, mem)();
//                    BackboneContext.get().track!(Alias!(__traits(getMember, mod_, mem)))();
                }
            }
        }
    }
    
    scanModule!(mod_.Index.packageName)();
    static foreach (string submodule; EnumMembers!(mod_.Index.submodules)){
        scanModule!(submodule);
    }
    static foreach (string subpackage; EnumMembers!(mod_.Index.subpackages)){
        scan!(subpackage);
    }
}

/*
void scan(string root)(){
    alias index = import_!(root~"._index", "Index");
    void scanModule(string name)(){
        auto m = module_!(name)();
        static foreach (Aggregate a; m.aggregates){
            pragma(msg, "scanned ", a);
            BackboneContext.get().track!(name, a.name)();
        }
    }
    scanModule!(__traits(getMember, index, "packageName"))();
    static foreach (string submodule; EnumMembers!(index.submodules)){
        scanModule!(submodule)();
    }
    
    static foreach (string subpackage; EnumMembers!(index.subpackages)){
        scan!(subpackage);
    }
}*/

version(unittest){
    import glued.annotations;
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
}

unittest {
    scan!("glued")();
    writeln(BackboneContext.get().tracked);
    writeln(BackboneContext.get().stereotypes);
}
