module glued.context.di.providers;

import std.traits;

import glued.annotations;
import glued.logging;

import glued.context.resolveCall;

import glued.context.di.annotations;
import glued.context.di.initializers;

import dejector;

extern (C) Object _d_newclass(const TypeInfo_Class ci);

//todo is(class)
class ComponentClassProvider(T): Provider {
    mixin CreateLogger;
    private Logger log;

    this(LogSink logSink){
        log = Logger(logSink);
    }

    override Initialization get(Dejector injector){
        log.debug_.emit("Building seed of type ", fullyQualifiedName!T);
        auto seed = cast(T) _d_newclass(T.classinfo);
        log.debug_.emit("Built seed ", &seed, " of type ", fullyQualifiedName!T);
        return new Initialization(seed, false, new ComponentSeedInitializer!T(injector));
    }
}

class ConfigurationMethodProvider(C, string name, size_t i): Provider {
    mixin CreateLogger;
    private Logger log;

    this(LogSink logSink){
        log = Logger(logSink);
    }

    override Initialization get(Dejector injector){
        log.debug_.emit("Resolving configuration class instance ", fullyQualifiedName!C);
        C config = injector.get!C;
        log.debug_.emit("Resolved configuration class ", fullyQualifiedName!C, " instance ", &config);
        log.debug_.emit("Building configuration method ", fullyQualifiedName!C, ".", name);
        auto instance = resolveCall(injector, &(__traits(getOverloads, config, name)[i]));
        enum isSeed = hasOneAnnotation!(__traits(getOverloads, C, name)[i], Seed); //todo assert not has many
        log.debug_.emit("Built initialized instance ", &instance, " method ", fullyQualifiedName!C, ".", name);
        auto initializer = isSeed ? new InstanceInitializer!(C, true)(injector) : new NullInitializer;
        return new Initialization(cast(Object) instance, !isSeed, cast(Initializer) initializer);
    }
}
