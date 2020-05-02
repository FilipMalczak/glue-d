module glued.application.di.resolveCall;

import std.traits: moduleName, fullyQualifiedName;
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
        result ~= "injector.get!("~fullyQualifiedName!p~")";
    }
    result ~= params.join(", ");
    result ~= ")";
    return result;
}

//todo reusable and useful
auto resolveCall(R, P...)(Dejector injector, R function(P) toCall){
    return resolveCall(injector, toDelegate(foo));
}

auto resolveCall(R, P...)(Dejector injector, R delegate(P) toCall){
    mixin CreateLogger;

    mixin(generateImports!(P)());
    static if (is(ReturnType!foo == void)){
        mixin(Logger.logged!(generateResolvedExpression!(P)()~";"));
    } else {
        mixin(Logger.logged.value!("return "~generateResolvedExpression!(P)()~";"));
    }
}
