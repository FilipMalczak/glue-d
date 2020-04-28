module glued.context.di.annotations;

struct Bind(T) {
    alias As = T;
}

struct IgnoreResultBinding {}

/**
 * "existing instance that should be autowired further". If you put this on configuration method, returned
 * instance will be considered "seed"
 */
struct Seed {}

struct Constructor {}

struct PostConstruct {}

//todo predestruct


enum DefaultQuery;
//todo Autowire (verb, imperative) or Autowired (adj, declarative)?
struct Autowire(T=DefaultQuery) {
    alias Query = T;
}
