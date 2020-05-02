module glued.codescan.listener;

import std.meta;
import std.typecons;

import glued.codescan.scannable;

interface Listener(State) 
{
    void init(State state);

    void onScannable(alias scannable)() if (isScannable!scannable);
    
    void onType(T)();
    
    void onBundleModule(string modName)();
    
    void onScannerFreeze();
}

class CompositeListener(State, Listeners...): Listener!State  
//    if (allSatisfy!(L => is(L: Listener!State) && __traits(compiles, new L()), Listeners)) //todo
{
    private Tuple!(AliasSeq!(Listeners)) listeners;

    this()
    {
        static foreach (i, L; Listeners) 
        { 
            listeners[i] = new L();
        }
    }
    
    void init(State state)
    {
        static foreach (i, L; Listeners) 
        { 
            listeners[i].init(state);
        }
    }
    
    void onScannable(alias scannable)() if (isScannable!scannable)
    {
        static foreach (i, L; Listeners) 
        { 
            listeners[i].onScannable!(scannable)();
        }
    }
    
    void onType(T)()
    {
        static foreach (i, L; Listeners) 
        { 
            listeners[i].onType!(T)();
        }
    }
    
    void onBundleModule(string modName)()
    {
        static foreach (i, L; Listeners) 
        { 
            listeners[i].onBundleModule!(modName)();
        }
    }
    
    void onScannerFreeze()
    {
        static foreach (i, L; Listeners) 
        { 
            listeners[i].onScannerFreeze();
        }
    }
}
