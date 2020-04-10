module glued.utils;

struct StringBuilder {
    string result;
    
    void append(string line, bool newLine=true){
        result ~= line ~ (newLine ? "\n" : "");
    }
}

template ofType(alias T) {
    import std.traits;
//    enum ofType(alias X) = (is(typeof(X) == T));
    static if (__traits(isTemplate, T)){
//        pragma(msg, "T ", fullyQualifiedName!T, " is template");
        enum ofType(alias X) = (__traits(isSame, TemplateOf!(typeof(X)), T));
    } else {
//        pragma(msg, "T ", T, " is type");
        enum ofType(alias X) = (is(typeof(X) == T));
    }
}

enum None;
