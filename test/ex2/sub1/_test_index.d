module ex2.sub1._test_index;
struct Index {
    enum packageName = "ex2.sub1";
    enum importablePackage = false;

    enum submodules {
        ex2_sub1_m1 = "ex2.sub1.m1",
    }

    enum subpackages;

}
