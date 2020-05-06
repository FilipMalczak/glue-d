module glued.application.di.resolveCall;

import std.traits: moduleName, fullyQualifiedName, isCallable, Parameters, ReturnType;
import std.array: join;

import glued.logging;

import dejector;

string generateImports(P...)(){
    string result;
    static foreach (p; P){
        result ~= "import "~moduleName!p~";\n";
    }
    return result;
}


string generateResolvedExpression(P...)(){
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

auto resolveCall(F...)(Dejector injector, F toCall)
    if (isCallable!(F))
{
    alias R = ReturnType!F;
    alias P = Parameters!F;
    return resolveCall!(R, P)(cast(R delegate(P)) toDelegate(toCall));
}

//todo add @Param(int idx/string name, alias annotations)
auto resolveCall(R, P...)(Dejector injector, R delegate(P) toCall)
{
    mixin CreateLogger;
    static if (is(R == void)){
        mixin(Logger.logged!(generateImports!(P)()~generateResolvedExpression!(P)()~";"));
    } else {
        mixin(Logger.logged.value!(generateImports!(P)()~"return "~generateResolvedExpression!(P)()~";"));
    }
}
