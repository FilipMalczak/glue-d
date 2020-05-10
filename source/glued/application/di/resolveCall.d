module glued.application.di.resolveCall;

import std.meta;
import std.traits: moduleName, fullyQualifiedName, isCallable, Parameters, ReturnType;
import std.array: join;
import std.functional;

import glued.logging;
import glued.annotations;

import glued.application.di.annotations;

import dejector;

auto resolveCall(alias Def, F...)(Dejector injector, F foo)
    if (isCallable!(F))
{
    alias R = ReturnType!F;
    alias P = Parameters!F;
    auto toCall = cast(R delegate(P)) toDelegate(foo);
    
    static string generateImports(){
        string result;
        static foreach (p; P){
            result ~= "import "~moduleName!p~";\n";
        }
        return result;
    }


    static string generateResolvedExpression(){
        //todo extension point when we introduce environment (key/val config)
        string result = "toCall(";
        string[] params;
        static foreach (i, p; P){
            static if (hasOneAnnotation!(parameter!(Def, i), Autowire))
            {
                params ~= "injector.get!("~fullyQualifiedName!(getAnnotation!(parameter!(Def, i), Autowire).Query)~")";
            }
            else
            {
                params ~= "injector.get!("~fullyQualifiedName!p~")";
            }
        }
        result ~= params.join(", ");
        result ~= ")";
        return result;
    }
    
    mixin CreateLogger;
    static if (is(R == void)){
        mixin(Logger.logged!(generateImports()~generateResolvedExpression()~";"));
    } else {
        mixin(Logger.logged.value!(generateImports()~"return "~generateResolvedExpression()~";"));
    }
}
