# glue-d
 
> master: [![master status](https://img.shields.io/travis/FilipMalczak/glue-d/master?label=master)](https://travis-ci.org/FilipMalczak/glue-d/branches)
>
> dev: [![dev status](https://img.shields.io/travis/FilipMalczak/glue-d/dev?label=dev)](https://travis-ci.org/FilipMalczak/glue-d/branches)
 
Bunch of different D-lang tools glued together with some sprinkles on top.
 
The point is to implement autoscanning, implement some annotation system (both done)
then glue together a bunch of other projects: forked dejector for DI, mirror for
reflection. Together with that this will become full application context, with
runtime features, like autowiring, inheritance inspection and instantiation, as 
well as compile-time component scan, stereotyping, auto-implementation of interfaces,
etc.
 
Next integrations will probably include vibe-d and maybe some data drivers.
 
Heavily inspired by Spring.
 
## ToDo
 
> __bold__ are WIP and highest prio
 
* conceptual
  * Java has Beans, what should we call components? something plant-related, 
    "seed" seems alright as "uninitialized component"
  * decide whether Glued is a infrastructure or IoC framework
    * it its IoC, then DI, etc can stay in this repo
    * it its infrastructure, then scan, indexing, logging, etc should stay here,
      but integrations with vibe-d, etc should be extracted to "starter bundles"
    * I think I like IoC variant better, but with minimal external deps; it should
      be vibe-agnostic (so, components, stereotypes, indexing, etc should stay, but
      there should be different integrations for vibe-d, hunt, etc)
  * __figure out packaging__ - there are different qualifiers for source sets, they
    will probably be non-empty for libraries
    * figure out how to compose application from annotations pointing to scannables
    * figure out naming - what is library, what is "bundle"/"starter", etc; 
      we need some abstraction of library you depend on, add an annotation and
      autoconfiguration (scanning, defaults, etc) 
  * __figure out configuration and resources__ facilities
    * we will probably string txt = import(f) to read files in compile-time
    * we need some way to package binaries like Java resources
      * probably something like indexer that reads binaries and text, then
        generates _resources (or similar) module with enums containing byte[]
      * it will probably be integrated with indexer
    * some resources need to be deployed with the lib, some need to be present only
      during the build
* enhancements
  * __property=method/postcostruct injection__
  * refactor existing code to use logging
  * enhance tests
* new features
  * __annotations enhancements:__
    * validation (missing method/field/etc, only known Targets are types; 
      validations here are "has (no) parameter of type/name", "name matches" 
      with syntax sugar for "name starts/ends with")
    * @InheritAnnotations(target=aggregate/method/field) - if present, look into 
      superclasses and copy annotations from super 
  * __enhanced resolveCall and friends__
    * @Param(i/name, annotations...) - repeatable, used to define param-level annotations
      * this can be a good moment to introduce more strict @Repeatable, something with
        semantics "this annotation can be repeated up to once with given argument", 
        which would be useful to validate that there is single @Param per argument)
    * @Seed on non-config method? (that would probably require either merging 
      dejector to this repo, duplicating resolveCall here or moving seed, 
      the whole annotations module and probably some annotation definitions there)
  * environment (string/string key-value pairs)
    * injection with @Config with support for simple types
  * value registry (environment required)
    * config inspection
    * autobinding structs/enums/simple types with @Value
  * auto-bound LogSink (config required)
  * enhance dejector to allow for aliases and qualifiers
    * additional dispatch level - resolver (key -> binding)
  * indexing scanned classes (aliases/qualifiers in dejector will be useful, but
    not required; implementing in parallel will probably make API more consistent)
    * indexing by inheritance hierarchy
    * by stereotypes (with runtime-available stereotype instances)
  * auto interface binding (require indexing by inheritance and qualifiers+aliases in dejector)
  * vibe-d integration
    * controller stereotype & autobinding
    * repositories?
  * converters
    * you have component C1 in context
    * you have Converter!(C1, C2) in context
    * you have no C2 in context
    * Glue-D should figure out in runtime that it can provide C2 by applying 
      converter to C1 instance
    * tbd: how to treat such instances when it comes to autobinding and interface
      resolution? (these are 2 cases, actually)
