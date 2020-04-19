module glued.context.backbone;

import std.variant;

import glued.stereotypes;
import glued.annotations;
import glued.mirror;

struct StereotypeDefinition(S) if (is(S == struct)) {
    S stereotype;
    LocatedAggregate target;
}

//todo this is useful only for testing
class BackboneContext {
    private LocatedAggregate[] _tracked;
    private Variant[][LocatedAggregate] _stereotypes;

    void track(string m, string n)() {
        version(glued_debug) {
            pragma(msg, "Tracking ", m, "::", n);
        }
        alias aggr = import_!(m, n);
        static if (qualifiesForTracking!(aggr)()){
            version(glued_debug) {
                pragma(msg, "qualifies!");
            }
            auto a = aggregate!(m, n)();
            _tracked ~= a;

            void gatherStereotypes(S)(S s){
                _stereotypes[aggregate!(S)()] ~= Variant(StereotypeDefinition!S(s, a));
            }
            static foreach (alias s; getStereotypes!aggr) {
                gatherStereotypes(s);
            }
        }
    }

    @property
    public LocatedAggregate[] tracked(){
        return this._tracked;
    }

    @property
    public Variant[][LocatedAggregate] stereotypes(){
        return this._stereotypes;
    }

    static bool qualifiesForTracking(alias T)(){
        return hasAnnotation!(T, Tracked);
    }
}
