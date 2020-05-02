module glued.testsuites.codescan.common;

enum GatherPairsSetup(string fooName) = ("import glued.set; Set!Pair "~fooName~"() { Set!Pair result;");
enum GatherPairsConsumer(string m, string n) = "result.add(Pair(\""~m~"\", \""~n~"\"));";
enum GatherPairsTeardown = "return result; }";
