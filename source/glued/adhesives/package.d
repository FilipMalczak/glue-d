/**
 * "Adhesives" are components used by glue-d to perform the actual glueing.
 * They include DI component, type index, bundle registrar, etc.
 */
module glued.adhesives;

public import glued.adhesives.bundles: BundleRegistrar;
public import glued.adhesives.config: Config, ConfigEntry;
public import glued.adhesives.typeindex: InheritanceIndex;
public import glued.adhesives.typeresolver: InterfaceResolver;
