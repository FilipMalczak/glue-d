module glued.testsuites.scan.common;

enum static_(string s) = "static "~s;
enum GatherPairsSetup(string fooName) = ("Pair[] "~fooName~"() { Pair[] result;");
enum GatherPairsConsumer(string m, string n) = "result ~= Pair(\""~m~"\", \""~n~"\");";
enum GatherPairsTeardown = "return result; }";
