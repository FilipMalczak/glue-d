import generate_index;

void main(string[] args){
    processSourceSets([SourceSet("codescan/source", "", true, false), SourceSet("codescan/test", "scantest", false, true)]);
}
