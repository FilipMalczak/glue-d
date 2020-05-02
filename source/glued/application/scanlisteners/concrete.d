module glued.application.scanlisteners.concrete;

import std.traits;

import glued.logging;

import glued.codescan.scannable;
import glued.codescan.listener;

import glued.application.stereotypes;
import glued.application.di.providers;
import glued.application.di.annotations;

import dejector;

class ConcreteTypesListener: ScanListener!Dejector {
    mixin CreateLogger;
    private Logger log;
    private Dejector injector;

    void init(Dejector injector)
    {
        this.injector = injector;
        log = Logger(injector.get!LogSink);
    }

    void onScannable(alias scannable)() if (isScannable!scannable)
    {
        //todo track what scannable does type and its binding come from (?) - this is tricky and far in the future
    }
    
    void onType(A)() //A as in "aggregate"
    {
        static if (canHandle!A()) { //todo log about it
            static if (isMarkedAsStereotype!(A, Component)) {
                handleComponent!A();
            }
            static if (isMarkedAsStereotype!(A, Configuration)){
                handleConfiguration!A();
            }
        }
    }
    
    void onBundleModule(string modName)()
    {
    }
    
    void onScannerFreeze()
    {
    }

    private static bool canHandle(A)(){
        return is(A == class);
    }
    
    private void handleComponent(A)(){
        log.info.emit("Binding ", fullyQualifiedName!A);
        injector.bind!(A)(new ComponentClassProvider!A(log.logSink));
        log.info.emit("Bound ", fullyQualifiedName!A, " based on its class definition");
    }

    private void handleConfiguration(A)(){
        log.info.emit("Binding based on configuration ", fullyQualifiedName!A);
        injector.bind!(A, Singleton)(new ComponentClassProvider!A(log.logSink));
        static foreach (name; __traits(allMembers, A)){
            static if (__traits(getProtection, __traits(getMember, A, name)) == "public" &&
            isFunction!(__traits(getMember, A, name))) {
                static foreach (i, overload; __traits(getOverloads, A, name)) {
                    static if (hasAnnotation!(overload, Component)) {
                        static if (!hasAnnotation!(overload, IgnoreResultBinding)){
                            //todo reuse the same provider for many bindings
                            log.info.emit("Binding type "~fullyQualifiedName!(ReturnType!overload)~" with method ", fullyQualifiedName!A, ".", name, "[#", i, "]");
                            injector.bind!(ReturnType!overload)(new ConfigurationMethodProvider!(A, name, i)(log.logSink));
                            log.info.emit("Bound "~fullyQualifiedName!(ReturnType!overload)~" with method ", fullyQualifiedName!A, ".", name, "[#", i, "]");
                        } //todo else assert exactly one ignore and any Bind

                        static foreach (bind; getAnnotations!(overload, Bind)){
                            log.info.emit("Binding type "~fullyQualifiedName!(Bind.As)~" with method ", fullyQualifiedName!A, ".", name, "[#", i, "]");
                            injector.bind!(Bind.As)(new ConfigurationMethodProvider!(A, name, i)(log.logSink));
                            log.info.emit("Bound "~fullyQualifiedName!(Bind.As)~" with method ", fullyQualifiedName!A, ".", name, "[#", i, "]");
                        }
                    }
                }
            }
        }
        log.info.emit("Bound chosen members on configuration ", fullyQualifiedName!A);
    }
}
