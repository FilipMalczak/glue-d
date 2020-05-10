module glued.application.di.resolveCall;

import std.traits: moduleName, fullyQualifiedName, isCallable, Parameters, ReturnType;
import std.array: join;
import std.functional;

import glued.logging;

import dejector;

auto resolveCall(F...)(Dejector injector, F foo)
    if (isCallable!(F))
{
    alias R = ReturnType!F;
    alias P = Parameters!F;
    auto toCall = cast(R delegate(P)) toDelegate(foo);
    
    string generateImports(){
        string result;
        static foreach (p; P){
            result ~= "import "~moduleName!p~";\n";
        }
        return result;
    }


    string generateResolvedExpression(){
        //todo extension point when we introduce environment (key/val config)
        string result = "toCall(";
        string[] params;
        static foreach (p; P){
            params ~= "injector.get!("~fullyQualifiedName!p~")";
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
