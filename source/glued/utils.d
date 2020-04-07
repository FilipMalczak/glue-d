module glued.utils;

import std.range: padLeft;
import std.conv: to;
import std.meta: AliasSeq;

struct StringBuilder {
    string result;
    
    void append(string line, bool newLine=true){
        result ~= line ~ (newLine ? "\n" : "");
    }
}

template ofType(T) {
    enum ofType(alias X) = (is(typeof(X) == T));
}

enum None;

struct Log(string f=__FILE__, int l=__LINE__){
    alias logPrefix(string f, int l) = AliasSeq!("@", padLeft(f, 20, " ") , ":", padLeft(to!string(l), 4, " "), " -> ");

    mixin template static_(T...){
        version(glued_debug){
            pragma(msg, logPrefix!(f, l), T);
        } 
        enum static_ = 0;
    }
    
    alias s = static_;
    
    static void dynamic(T...)(T t){
        version(glued_verbose) {
            import std.stdio: stderr;
            stderr.writeln(logPrefix!(f, l) , t);
        }
    }
    
    alias d = dynamic;
}

mixin template logged(string toMixin, string f=__FILE__, int l=__LINE__){
    alias L = Log!(f, l);
    mixin L.static_!("Mixing in: \n", toMixin);
    mixin toMixin;
}
