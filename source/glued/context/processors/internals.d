module glued.context.processors.internals;

import glued.logging: LogSink;

import glued.context.typeindex: InheritanceIndex;

import dejector: Dejector;

struct GluedInternals {
    Dejector injector;
    LogSink logSink;
    InheritanceIndex inheritanceIndex;
}
