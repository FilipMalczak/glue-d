module glued.utils;

import std.meta;
import std.range;
import std.traits;

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
    //todo message
    static assert(isType!(toType)); //to fail on functions, methods, etc
}

//fixme fugly name, its nothing to do with annotations, but I have no better idea now
template toAnnotableType(alias T){
    alias toTypes = AliasSeq!(NoDuplicates!(typeof(T), toType!(T)));
}

enum isType(T) = (__traits(isTemplate, T) || is(T == class) || is(T == interface) || is(T == struct) || is(T == enum));

template isRangeOf(R, T) {
    enum isRangeOf = isInputRange!R && is(ReturnType!((R r) => r.front()) == T);
}

//todo remove these from dejector, make dependency on utils and logging from there
enum isObjectType(T) = is(T == interface) || is(T == class);
enum isValueType(T) = is(T == struct) || is(T==enum);

T nonNull(T)(T t) if (isObjectType!T) {
    assert(t !is null); //todo exception
    return t;
}

bool isInstance(T, V)(V v) if (isObjectType!T && isObjectType!V){
    T t = cast(T) v;
    return t !is null;
}
