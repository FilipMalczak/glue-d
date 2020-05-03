module glued.application.scanlisteners.interfaces;

import std.array;
import std.algorithm;
import std.traits;

import glued.logging;
import glued.utils;
import glued.set;

import glued.codescan.scannable;
import glued.codescan.listener;

import glued.application.stereotypes;

import glued.adhesives.typeresolver;
import glued.adhesives.typeindex: InheritanceIndex, TypeKind;

import dejector;

class InterfaceListener: ScanListener!Dejector {
    mixin CreateLogger;
    private Logger log;
    private Dejector injector;
    private InheritanceIndex inheritanceIndex;
    private InterfaceResolver resolver;

    void init(Dejector injector)
    {
        this.injector = injector;
        log = Logger(injector.get!LogSink);
        inheritanceIndex = new InheritanceIndex(injector.get!LogSink);
        injector.bind!(InheritanceIndex)(new InstanceProvider(inheritanceIndex));
        resolver = new InterfaceResolver(injector);
        injector.bind!(InterfaceResolver)(new InstanceProvider(resolver));
        
    }

    void onScannable(alias scannable)() if (isScannable!scannable)
    {
        //todo track what scannable does asset come from
    }
    
    void onType(A)() //A is for "aggregate"
    {
        static if (canHandle!A()) //todo log about it
        {
            immutable key = fullyQualifiedName!A; //todo queryString?
            log.debug_.emit("Handling ", key);
            static if (is(A == interface))
            {
                immutable kind = TypeKind.INTERFACE;
            }
             else 
            {
                static if (__traits(isAbstractClass, A)) 
                {
                    immutable kind = TypeKind.ABSTRACT_CLASS;
                }
                else
                {
                    immutable kind = TypeKind.CONCRETE_CLASS;
                }
            }
            log.debug_.emit("Kind: ", kind);
            inheritanceIndex.markExists(key, kind);
            import std.traits;
            static foreach (b; BaseTypeTuple!A){
                static if (!is(b == Object)){
                    //todo ditto
                    log.trace.emit(fullyQualifiedName!A, " extends ", fullyQualifiedName!b);
                    inheritanceIndex.markExtends(fullyQualifiedName!A, fullyQualifiedName!b);
                    onType!(b)();
                }
            }
        }
    }
    
    void onBundleModule(string modName)()
    {
    }
    
    void onScannerFreeze()
    {
        log.debug_.emit("Trying to bind interfaces");
        foreach (i; inheritanceIndex.find(TypeKind.INTERFACE)){
            auto impls = inheritanceIndex.getImplementations(i).array;
            if (impls.length == 1){
                log.debug_.emit("Binding interface ", i, " with sole implementation ", impls[0]);
                injector.bind(i, impls[0]);
            } else {
                if (impls.length == 0){ //todo turn off somehow; by log level, or maybe by dedicated config entry?
                    log.warn.emit("Interface ", i, " has no implementation in current context!");
                }
            }
        }
    }

    private static bool canHandle(A)(){
        //todo reuse isObjectType from dejector
        return is(A == interface) || is(A == class);
    }
}
