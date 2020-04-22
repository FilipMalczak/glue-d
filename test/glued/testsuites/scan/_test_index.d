module glued.testsuites.scan._test_index;
struct Index {
    enum packageName = "glued.testsuites.scan";
    enum importablePackage = false;
    enum hasBundle = false;
    enum bundleModule;

    enum submodules {
        glued_testsuites_scan_common = "glued.testsuites.scan.common",
        glued_testsuites_scan_with_externally_defined = "glued.testsuites.scan.with_externally_defined",
        glued_testsuites_scan_with_locally_defined = "glued.testsuites.scan.with_locally_defined",
        glued_testsuites_scan_scanner_def = "glued.testsuites.scan.scanner_def",
        glued_testsuites_scan_with_tracking_by_context = "glued.testsuites.scan.with_tracking_by_context",
    }

    enum subpackages;

}
