module glued.testsuites.context;

import glued.context;
import glued.scannable;

unittest {
    auto d = new shared GluedContext;
    
    d.scan!([at("ex1")])();
    
    import ex1.scan_aggregates: Z;
    Z inst = d.internalContext.resolve!Z;
    assert(inst !is null);
}
