import std.stdio;
import std.algorithm;
import std.array;
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

bool isIgnoredFile(string path)
{
    return path.startsWith("_");
}

bool isPackageFile(string path)
{
    return path == "package.d";
}

bool isIndexableFile(DirEntry d)
{
    return d.isFile && d.name.extension == ".d" && 
        !isIgnoredFile(d.name.baseName()) && 
        !isPackageFile(d.name.baseName());
}

struct SourceSet {
    string path;
    string infix;
    bool isMain;
    bool upgenerate;
    
    @property
    string prefix(){
        return infix.length ? "_"~infix : "";
    } 
}

auto parseSourceSets(string[] args){
    SourceSet[] sourceSets;
    foreach (size_t i, string def; args)
    {
        string delimiter;
        bool isMain, upgenerate;
        
        if (def.count("+"))
        {
            assert(i);
            delimiter = "+";
            isMain = false;
            upgenerate = true;
        } 
        else
        if (def.count("-"))
        {
            assert(i);
            delimiter = "+";
            isMain = false;
            upgenerate = false;
        }
        else
        {
            assert(!i);
            delimiter = ":";
            isMain = true;
            upgenerate = false;
        }
        auto parts = def.split(delimiter);
        auto path = parts[0];
        string infix;
        assert(parts.length < 3);
        if (parts.length == 1) 
        {
            assert(i==0);
        }
        else
        {
            infix = parts[1];
        }
        sourceSets ~= SourceSet(path, infix, isMain, upgenerate);
    }
    return sourceSets;
}

void writeEnum(File pkgFile, string name, string[] entries)
{
    pkgFile.write("    enum "~name);
    if (entries.length) {
        pkgFile.writeln(" {");
        foreach (line; entries)
            pkgFile.writeln(line);
        pkgFile.writeln("    }");
    }
    else
        pkgFile.writeln(";");
}

void writeSubmodules(File pkgFile, string sourceSet, string packagePath)
{
    string[] fileLines = [];
    foreach(DirEntry d; dirEntries(packagePath, SpanMode.shallow)){
        if (isIndexableFile(d)){
            auto modName = toModuleName(sourceSet, d.name);
            auto enumName = toEnumName(modName);
            fileLines ~= "        "~enumName~" = \""~modName~"\",";
        }
    }
    writeEnum(pkgFile, "submodules", fileLines);
}

void writeSubpackages(File pkgFile, string sourceSet, string packagePath)
{
    string[] subdirLines = [];
    foreach(DirEntry d2; dirEntries(packagePath, SpanMode.shallow)){
        if (d2.isDir){
            auto modName = toModuleName(sourceSet, d2.name);
            auto enumName = toEnumName(modName);
            subdirLines ~= "        "~enumName~" = \""~modName~"\",";
        }
    }
    writeEnum(pkgFile, "subpackages", subdirLines);
}

string rebase(string path, string root, string newRoot)
{
    return to!string(newRoot.chainPath(path.absolutePath.relativePath(root.absolutePath)));
//    return chainPath(newRoot, relativePath(absolutePath(path), absolutePath(root)));
}

void generateIndex(SourceSet sourceSet, SourceSet main, DirEntry d, bool hasBundle){
    auto indexName = sourceSet.prefix ~ "_index";
    auto pkgFilePath = chainPath(d.name, indexName~".d");
    writeln(__FILE__, ":", __LINE__, " ", "Generating ", pkgFilePath);
    auto pkgFile = File(pkgFilePath,"w");
    auto packageName = toModuleName(sourceSet.path, d.name);
    pkgFile.writeln("module "~packageName~"."~indexName~";");
    pkgFile.writeln("struct Index {");
    pkgFile.writeln("    enum packageName = \""~packageName~"\";");
    bool packageFileExists = chainPath(d.name, "package.d").exists;
    pkgFile.writeln("    enum importablePackage = "~to!string(packageFileExists)~";");
    pkgFile.writeln("    enum hasBundle = "~to!string(hasBundle)~";");
    if (hasBundle){
        pkgFile.writeln("    enum bundleModule = \""~packageName~"."~sourceSet.prefix ~ "_bundle\";");
    } else {
        pkgFile.writeln("    enum bundleModule;");
    }
    pkgFile.writeln();
    writeSubmodules(pkgFile, sourceSet.path, d.name);
    pkgFile.writeln();
    writeSubpackages(pkgFile, sourceSet.path, d.name);
    
    pkgFile.writeln();

    pkgFile.writeln("}");
    if (sourceSet.upgenerate) 
    {
        indexName = main.prefix~"_index";
        auto mainIndex = chainPath(rebase(d.name, sourceSet.path, main.path), indexName~".d");
        if (!mainIndex.exists)
        {   
            auto upgeneratedIndex = chainPath(d.name, indexName~".d");
            writeln(__FILE__, ":", __LINE__, " ", "Upgenerating ", upgeneratedIndex);
            auto upgeneratedFile = File(upgeneratedIndex, "w");
            upgeneratedFile.writeln("module "~packageName~"."~indexName~";");
            upgeneratedFile.writeln();
            upgeneratedFile.writeln("struct Index {");
            upgeneratedFile.writeln("    enum packageName = \""~packageName~"\";");
            packageFileExists = chainPath(d.name, "package.d").exists;
            upgeneratedFile.writeln("    enum importablePackage = "~to!string(packageFileExists)~";");
            upgeneratedFile.writeln("    enum hasBundle = false;");
            upgeneratedFile.writeln("    enum bundleModule;");
            upgeneratedFile.writeln();
            upgeneratedFile.writeln("    enum submodules;");
            upgeneratedFile.writeln();
            upgeneratedFile.writeln("    enum subpackages;");
            upgeneratedFile.writeln();
            upgeneratedFile.writeln("}");
        }
    }
}

//returns whether any files were bundled in this directory
bool generateBundle(SourceSet sourceSet, DirEntry d){
    auto descriptorPath = chainPath(d.name, ".bundle");
    if (descriptorPath.exists){
        auto descriptorFile = File(descriptorPath, "r");
        auto toBundle = descriptorFile.byLineCopy.array;
        writeln(__FILE__, ":", __LINE__, " ", "toBundle: ", toBundle);
        if (toBundle.empty) {
            writeln(__FILE__, ":", __LINE__, " ", "Empty bundle");
            return false;
        }
        auto bundleName = sourceSet.prefix ~ "_bundle";
        auto bundlePath = chainPath(d.name, bundleName~".d");
        writeln(__FILE__, ":", __LINE__, " ", "Generating ", bundlePath);
        auto bundleFile = File(bundlePath,"w");
        auto packageName = toModuleName(sourceSet.path, d.name);
        bundleFile.writeln("module "~packageName~"."~bundleName~";");
        bundleFile.writeln();
        bundleFile.writeln("struct BundleDefinition {");
        bundleFile.writeln("    enum bundledFiles = loadBundle();");
        bundleFile.writeln();
        bundleFile.writeln("    private static string[string] loadBundle(){ ");
        bundleFile.writeln("        string[string] result;");
        foreach (f; toBundle){
            auto path = to!string(chainPath(d.name, f));
            version(Windows)
            {
                //https://github.com/dlang/dmd/pull/6739#issue-118364974
                //apparently on Windows we cannot import files that have backslash
                //in path, but we still can use simple slash
                path = path.replace("\\", "/");
            }
            bundleFile.writeln("        result[\""~f~"\"] = import(\""~path~"\");");
        }
        bundleFile.writeln("        return result;");
        bundleFile.writeln("    }");
        bundleFile.writeln();

        bundleFile.writeln("}");
        return true;
    } else {
        return false;
    }
}

void processSourceSets(SourceSet[] sourceSets=[SourceSet("source", "", true, false), SourceSet("test", "test", false, true)]){
    SourceSet main;
    foreach (SourceSet p; sourceSets)
    {
        if (p.isMain) 
        {
            main = p;
            break;
        }
    }
    writeln(__FILE__, ":", __LINE__, " ", "Source sets: ", sourceSets);
    writeln(__FILE__, ":", __LINE__, " ", "Main:        ", main);
    foreach (SourceSet sourceSet; sourceSets)
    {
        foreach (DirEntry d; dirEntries(sourceSet.path, SpanMode.breadth))
        {
            if (d.isDir) 
            {
                auto hasBundle = generateBundle(sourceSet, d);
                generateIndex(sourceSet, main, d, hasBundle);
            }
        }
    }
}

//todo its not generate_index but rather preprocess_codebase or smth
version(executable) {
    /**
     * Params (in order):
     * mainSourceSet(:infix)
     * sourceSet:infix*
     */
    void main(string[] args){
        assert(args.length > 1);
        SourceSet[] sourceSets = parseSourceSets(args[1..$]);
        processSourceSets(sourceSets);
    }

}
