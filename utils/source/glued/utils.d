module glued.utils;

import std.meta;

struct StringBuilder {
    string result;
    
    void append(string line, bool newLine=true){
        result ~= line ~ (newLine ? "\n" : "");
    }
}

template ofType(alias T) {
    import std.traits;
    static if (__traits(isTemplate, T)){
        enum ofType(alias X) = (__traits(isSame, TemplateOf!(typeof(X)), T));
    } else {
        enum ofType(alias X) = (is(typeof(X) == T));
    }
}

template toType(alias T){
    import std.traits;
    static if (__traits(isTemplate, T)){
        alias toType = TemplateOf!(typeof(T));
    } else {
        alias toType = typeof(T);
    }
    static assert(isType!(toType)); //to fail on functions, methods, etc
}

//fixme fugly name, its nothing to do with annotations, but I have no better idea now
template toAnnotableType(alias T){
    alias toTypes = AliasSeq!(NoDuplicates!(typeof(T), toType!(T)));
}

enum isType(T) = (__traits(isTemplate, T) || is(T == class) || is(T == interface) || is(T == struct) || is(T == enum));
