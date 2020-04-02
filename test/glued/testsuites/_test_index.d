module glued.testsuites._test_index;
struct Index {
    enum packageName = "glued.testsuites";
    enum importablePackage = false;

    enum submodules;

    enum subpackages {
        glued_testsuites_scan = "glued.testsuites.scan",
    }

}
