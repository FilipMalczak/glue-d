module glued.scannable;

import std.string;
import std.traits;


struct Scannable {
    string root;
    string qualifier = "";
    string testQualifier = "test";
    
    @property
    string prefix(){
        return _prefix(qualifier);
    }
    
    @property
    string testPrefix(){
        return _prefix(testQualifier);
    }
    
    private static string _prefix(string q){
        return q.length ? "_"~q : "";
    }
}

Scannable at(string root, string qualifier="", string testQualifier="test"){
    return Scannable(root, qualifier, testQualifier);
}

Scannable at(Scannable s){
    return s;
}

Scannable with_(Scannable s, string r="",string q="", string tq=""){
    with (s) {
        if (r)
            root = r;
        if (q)
            qualifier = q;
        if (tq)
            testQualifier = tq;
    }
    return s;
}

Scannable fromRoot(string moduleName, string qualifier="", string testQualifier="test"){
    string[] parts = moduleName.split(".");
    assert(parts.length);
    //todo add reading qualifiers from some source file
    return Scannable(parts[0], qualifier, testQualifier);
}

enum from(T, string qualifier="", string testQualifier="test") = fromRoot(moduleName!T, qualifier, testQualifier);

enum here(string qualifier="", string testQualifier="test") = from(__FUNCTION__, qualifier, testQualifier);

