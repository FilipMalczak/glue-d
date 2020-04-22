module bundles.content.onlysubpkgs._test_bundle;

struct BundleDefinition {
    enum bundledFiles = loadBundle();

    private static string[string] loadBundle(){ 
        string[string] result;
        result["f1.txt"] = import("test/bundles/content/onlysubpkgs/f1.txt");
        return result;
    }

}
