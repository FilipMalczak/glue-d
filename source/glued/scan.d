module glued.scan;

import std.conv: to;
import std.traits;
import std.meta;
import std.string;

import glued.mirror;
import glued.utils;

public import glued.scannable;

string scanModule(string name, alias consumer)(){
    StringBuilder builder;
    static if (!isGluedImplModule(name))
        {
        mixin("static import "~name~";");
        mixin("alias mod_ = "~name~";");
        static foreach (alias mem; __traits(allMembers, mod_)){
            static if (__traits(compiles, __traits(getMember, mod_, mem))){
                static if (is(__traits(getMember, mod_, mem))){
                    builder.append(consumer!(name, mem));
                }
            }
        }
    }
    return builder.result;
}

string scanIndexModule(string index, alias consumer)(){
    StringBuilder builder;
    mixin("static import "~index~";");
    mixin("alias mod_ = "~index~";");
    
    static if (mod_.Index.importablePackage)
        builder.append(scanModule!(mod_.Index.packageName, consumer)());
    static foreach (string submodule; EnumMembers!(mod_.Index.submodules)){
        builder.append(scanModule!(submodule, consumer)());
    }
    static foreach (string subpackage; EnumMembers!(mod_.Index.subpackages)){
        builder.append(prepareScan!(subpackage, NoOp, NoOp, consumer, qualifier, testQualifier)()); //todo qualifiers
    }
    return builder.result;
}

bool isGluedImplModule(string name)
{
    auto parts = name.split(".");
    if (parts.length == 2)
        return parts[0] == "glued";
    return false;
}

string prepareScan(alias roots, string setup, alias consumer, string teardown)(){
    StringBuilder builder;
    builder.append(setup);
    static foreach (alias scannable; roots) {
        
        static assert(is(typeof(scannable) == Scannable)); //todo could be smartly expressed with conditional method 
        builder.append(scanIndexModule!(scannable.root~"."~scannable.prefix~"_index", consumer)());
        version(unittest){
            builder.append(scanIndexModule!(scannable.root~"."~scannable.testPrefix~"_index", consumer)());
        }
    }
    builder.append(teardown);
    return builder.result;
}

enum NoOp = "";

Scannable[] listScannables(Scannable s) {
    return [s];
}

Scannable[] listScannables(Scannable[] s){
    return s;
}

mixin template unrollLoopThrough(alias roots, string setup, alias consumer, string teardown, 
    string f=__FILE__, int l=__LINE__, string m=__MODULE__, string foo=__FUNCTION__, string prettyFoo=__PRETTY_FUNCTION__){
    import glued.logging;
    mixin CreateLogger!();
    mixin(Logger.logged!(f, l, m, foo, prettyFoo)().value!(prepareScan!(listScannables(roots), setup, consumer, teardown)()));
}
