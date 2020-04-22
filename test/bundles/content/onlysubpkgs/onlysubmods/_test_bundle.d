module bundles.content.onlysubpkgs.onlysubmods._test_bundle;

struct BundleDefinition {
    enum bundledFiles = loadBundle();

    private static string[string] loadBundle(){ 
        string[string] result;
        result["f2.txt"] = import("test/bundles/content/onlysubpkgs/onlysubmods/f2.txt");
        return result;
    }

}
