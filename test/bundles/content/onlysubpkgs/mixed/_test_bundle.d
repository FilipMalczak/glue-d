module bundles.content.onlysubpkgs.mixed._test_bundle;

struct BundleDefinition {
    enum bundledFiles = loadBundle();

    private static string[string] loadBundle(){ 
        string[string] result;
        result["f3.txt"] = import("test/bundles/content/onlysubpkgs/mixed/f3.txt");
        return result;
    }

}
