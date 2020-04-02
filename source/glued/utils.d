module glued.utils;

struct StringBuilder {
    string result;
    
    void append(string line, bool newLine=true){
        result ~= line ~ (newLine ? "\n" : "");
    }
}

template ofType(T) {
    enum ofType(alias X) = (is(typeof(X) == T));
}

struct None{}
