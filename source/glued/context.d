module glued.context;

import std.variant;

import glued.annotations;
import glued.stereotypes;
import glued.mirror;

//todo is this a good idea?
template Root(T) if (is(T == class)) {
    struct Root { 
        private static T instance;
        private static bool initialized = false;

        private T value;
        
        alias value this;
        
        public static Root get(){
            //todo if !initialized
            return Root(instance);
        }
                
        public static void initialize(T instance){
            if (!initialized) 
            {
                Root.initialized  = true;
                Root.instance = instance;
            } else
            //todo
                throw new Exception("already initialized!");
        }
    }
}

mixin template HasSingleton() {
    static this(){
        Root!(typeof(this)).initialize(new typeof(this)());
    }
    
    static typeof(this) get(){
        return Root!(typeof(this)).get().value;
    }
}

struct StereotypeDefinition(S) if (is(S == struct)) {
    S stereotype;
    LocatedAggregate target;
}

class BackboneContext {
    mixin HasSingleton;
    
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

version(unittest){
    class TestContext {
        string val;
        
        mixin HasSingleton;
    }
}

unittest {
    assert(Root!TestContext.get().val == "");
    assert(TestContext.get().val == "");
    Root!TestContext.get().val = "abc";
    assert(Root!TestContext.get().val == "abc");
    assert(TestContext.get().val == "abc");
    TestContext.get().val = "def";
    assert(Root!TestContext.get().val == "def");
    assert(TestContext.get().val == "def");
}
