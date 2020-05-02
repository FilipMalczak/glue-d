module glued.application.scanlisteners;

import std.meta;

public import glued.application.scanlisteners.concrete: ConcreteTypesListener;
public import glued.application.scanlisteners.interfaces: InterfaceListener;
public import glued.application.scanlisteners.bundles: BundlesListener;

alias GluedAppListeners = AliasSeq!(ConcreteTypesListener, InterfaceListener, BundlesListener);
