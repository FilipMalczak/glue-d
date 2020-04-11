module glued.utils;

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

