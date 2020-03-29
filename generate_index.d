import std.stdio;
import std.file;
import std.path;
import std.conv;
import std.string;

string toModuleName(string base, string path){
    string[] splitted = [];
    foreach (p; pathSplitter(stripExtension(relativePath(absolutePath(path), absolutePath(base)))))
        splitted ~= p;
    if (splitted[$-1] == "package")
        splitted = splitted[0..$-1];
    return splitted.join(".");
}

string toEnumName(string moduleName){
    return moduleName.split(".").join("_");

}

void main(string[] args){
    assert(args.length==2);
    foreach (DirEntry d; dirEntries(args[1], SpanMode.breadth))
        if (d.isDir) {
            auto pkgFilePath = chainPath(d.name, "_index.d");
            auto pkgFile = File(pkgFilePath,"w");
            pkgFile.writeln("module "~toModuleName(args[1], d.name)~"._index;");
            pkgFile.writeln();
            pkgFile.writeln("struct Index {");
            pkgFile.writeln("    enum packageName = \""~toModuleName(args[1], d.name)~"\";");
            pkgFile.writeln();
            pkgFile.write("    enum submodules");
            string[] fileLines = [];
            foreach(DirEntry d2; dirEntries(d.name, SpanMode.shallow)){
                if (d2.isFile && d2.name.extension == ".d" && d2.name.baseName() != "_index.d" && d2.name.baseName() != "package.d"){
                    auto modName = toModuleName(args[1], d2.name);
                    auto enumName = toEnumName(modName);
                    fileLines ~= "        "~enumName~" = \""~modName~"\",";
                }
            }
            if (fileLines.length) {
                pkgFile.writeln(" {");
                foreach (line; fileLines)
                    pkgFile.writeln(line);
                pkgFile.writeln("    }");
            }
            else
                pkgFile.writeln("    ;");
            pkgFile.writeln();
            pkgFile.write("    enum subpackages");
            string[] subdirLines = [];
            foreach(DirEntry d2; dirEntries(d.name, SpanMode.shallow)){
                if (d2.isDir){
                    auto modName = toModuleName(args[1], d2.name);
                    auto enumName = toEnumName(modName);
                    subdirLines ~= "        "~enumName~" = \""~modName~"\",";
                }
            }
            if (subdirLines.length) {
                pkgFile.writeln(" {");
                foreach (line; subdirLines)
                    pkgFile.writeln(line);
                pkgFile.writeln("    }");
            }
            else
                pkgFile.writeln("    ;");
            pkgFile.writeln();

            pkgFile.writeln("}");
        }
}

