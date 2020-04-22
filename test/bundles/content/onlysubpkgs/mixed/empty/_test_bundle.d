module bundles.content.onlysubpkgs.mixed.empty._test_bundle;

struct BundleDefinition {
    enum bundledFiles = loadBundle();

    private static string[string] loadBundle(){ 
        string[string] result;
        result["f0.txt"] = import("test/bundles/content/onlysubpkgs/mixed/empty/f0.txt");
        return result;
    }

}
