module glued.context;

public import glued.context.annotations;
public import glued.context.backbone: BackboneContext;
public import glued.context.resolveCall: resolveCall;
public import glued.context.core: DefaultGluedContext, GluedContext;
public import glued.context.processors.interfaces: InterfaceResolver; //todo where should I keep things like this? maybe module like annotations? tools?
