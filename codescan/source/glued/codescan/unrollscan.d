module glued.codescan.unrollscan;

import std.conv: to;
import std.traits;
import std.meta;
import std.string;

import glued.mirror;
import glued.utils;

public import glued.codescan.scannable;

//DEV NOTE ON VISIBILITY LEVELS
//
//following functions are called statically during the mixin; because of that
//they need to be public, to be available on mixin point;
//if they are private, then module mixing them in won't be able to resolve
//them, even though they are in the same module as mixin (since mixins are
//evaluated at mixin point, not declaration point)

string scanModule(string name, alias aggregateConsumer)(){
    StringBuilder builder;
    mixin("static import "~name~";");
    mixin("alias mod_ = "~name~";");
    static foreach (alias mem; __traits(allMembers, mod_)){
        static if (__traits(compiles, __traits(getMember, mod_, mem))){
            static if (is(__traits(getMember, mod_, mem))){
                // if we encounter enum of form "enum Name;" (or "enum Name: int;")
                // we get:
                //    Error: enum ...Name is forward referenced looking for base type
                // or:
                //    Error: enum ...Name is forward referenced when looking for stringof
                // etc
                // To avoid that we filter out enums without members, which loosely relates to aforementioned situations
                //todo investigate how loosely
                static if (  
                    !is(__traits(getMember, mod_, mem) == enum) || 
                    EnumMembers!(__traits(getMember, mod_, mem)).length > 0
                )
                builder.append(aggregateConsumer!(name, mem));
            }
        }
    }
    return builder.result;
}

enum NoOp(T...) = "";

string scanIndexModule(string index, alias scannable, alias aggregateConsumer, alias bundleConsumer)(){
    StringBuilder builder;
    mixin("static import "~index~";");
    mixin("alias mod_ = "~index~";");
    static if (mod_.Index.hasBundle){
        builder.append(
            bundleConsumer!(mod_.Index.bundleModule)
        );
    }
    static if (mod_.Index.importablePackage)
        builder.append(
            scanModule!(mod_.Index.packageName, aggregateConsumer)()
        );
    static foreach (string submodule; EnumMembers!(mod_.Index.submodules)){
        builder.append(
            scanModule!(submodule, aggregateConsumer)()
        );
    }
    static foreach (string subpackage; EnumMembers!(mod_.Index.subpackages)){
        builder.append(
            prepareScan!(
                scannable.withRoot(subpackage), 
                "", 
                aggregateConsumer, 
                bundleConsumer, 
                ""
            )()); //todo qualifiers
    }
    return builder.result;
}

string prepareScan(alias scannable, string setup, alias aggregateConsumer, alias bundleConsumer, string teardown)(){
    StringBuilder builder;
    builder.append(setup);
    
    builder.append(
        scanIndexModule!(
            scannable.root~"."~scannable.prefix~"_index", 
            scannable, 
            aggregateConsumer, 
            bundleConsumer
        )()
    );
    
    version(unittest){
        builder.append(
            scanIndexModule!(
                scannable.root~"."~scannable.testPrefix~"_index", 
                scannable, 
                aggregateConsumer, 
                bundleConsumer
            )()
        );
    }
    
    builder.append(teardown);
    return builder.result;
}

mixin template unrollLoopThrough(alias scannable, string setup, alias aggregateConsumer, alias bundleConsumer, string teardown, 
    string f=__FILE__, int l=__LINE__, string m=__MODULE__, string foo=__FUNCTION__, string prettyFoo=__PRETTY_FUNCTION__)
    if (isScannable!(scannable))
{
    import glued.logging;
    mixin CreateLogger!();
    mixin(
        Logger.logged!(f, l, m, foo, prettyFoo)().value!(
            prepareScan!(
                scannable, 
                setup, 
                aggregateConsumer, 
                bundleConsumer, 
                teardown
            )()
        )
    );
}
