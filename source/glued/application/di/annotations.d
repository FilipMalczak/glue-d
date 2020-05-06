module glued.application.di.annotations;

/**
 * When present on configuration method, will bind that method as provider of
 * type defined with this annotation.
 */
struct Bind(T) {
    alias As = T;
}

/**
 * When present on configuration method, will NOT bind that method as provider of
 * return type of that method.
 */
struct IgnoreResultBinding {}

/**
 * "existing instance that should be autowired further". If you put this on 
 * configuration method, returned instance will be considered "seed" and standard
 * dependency injection will be performed on it.
 */
struct Seed {}

/**
 * Used to specify which constructor is called when initializing new instance.
 */
struct Constructor {}

//todo implement this
struct PostConstruct {}

//todo predestruct

///helper type to recognize autowiring by annotated target type
enum DefaultQuery;

//todo Autowire (verb, imperative) or Autowired (adj, declarative)?
/**
 * Used to specify dependencies (field and properties that should be injected)
 * and customize what will really be injected.
 */
struct Autowire(T=DefaultQuery) {
    alias Query = T;
}

/**
 * Used to indicate that annotated target should not be injected, e.g. when
 * injecting sole constructor.
 */
struct DontInject {}
