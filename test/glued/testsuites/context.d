module glued.testsuites.context;

import glued.context;
import glued.scannable;

unittest {
    auto d = new shared GluedContext;
    
    d.scan!([at("ex1")])();
}
