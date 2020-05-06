# glue-d

## What is it?
 
Bunch of different D-lang tools glued together with some sprinkles on top.
 
The point is to implement autoscanning, implement some annotation system (both done)
then glue together a bunch of other projects: forked dejector for DI, mirror for
reflection. Together with that this will become full application context, with
runtime features, like autowiring, inheritance inspection and instantiation, as 
well as compile-time component scan, stereotyping, auto-implementation of interfaces,
etc.
 
Next integrations will probably include vibe-d and maybe some data drivers.
 
Heavily inspired by Spring.

## Status

On Unix-like systems we build with latest compiler versions ([see details](https://docs.travis-ci.com/user/languages/d/), 
we don't specify version explicitly in the configuration).

Unfortunately, AppVeyor doesn't support per-job badges (at least [yet](https://github.com/appveyor/ci/issues/1805)).
We build our project with DMD (stable) on `x86` and `x64` and LDC (stable) on `x64`.

**GDC is explicitly not supported.**

### `master`

Really old, basically useless. Tagged just so that we have presence on dub.

### `dev`

[![codecov](https://codecov.io/gh/FilipMalczak/glue-d/branch/dev/graph/badge.svg)](https://codecov.io/gh/FilipMalczak/glue-d/branch/dev)
[![dev status](https://img.shields.io/travis/FilipMalczak/glue-d/dev?logo=travis)](https://travis-ci.org/FilipMalczak/glue-d/branches) 
[![dev status](https://ci.appveyor.com/api/projects/status/v4rff987qgocuxmf/branch/dev?svg=true)](https://ci.appveyor.com/project/FilipMalczak/glue-d/branch/dev)

Detailed status:
* ![xenial with dmd](https://badges.herokuapp.com/travis/FilipMalczak/glue-d?branch=dev&env=CI_CONTEXT=xenial_dmd&label=Ubuntu%20Xenial%20with%20dmd)
* ![bionic with dmd](https://badges.herokuapp.com/travis/FilipMalczak/glue-d?branch=dev&env=CI_CONTEXT=bionic_dmd&label=Ubuntu%20Bionic%20with%20dmd)
* ![osx with dmd](https://badges.herokuapp.com/travis/FilipMalczak/glue-d?branch=dev&env=CI_CONTEXT=osx_dmd&label=OSX%20with%20dmd)
* ![xenial with ldc](https://badges.herokuapp.com/travis/FilipMalczak/glue-d?branch=dev&env=CI_CONTEXT=xenial_ldc&label=Ubuntu%20Xenial%20with%20ldc)
* ![bionic with ldc](https://badges.herokuapp.com/travis/FilipMalczak/glue-d?branch=dev&env=CI_CONTEXT=bionic_ldc&label=Ubuntu%20Bionic%20with%20ldc)
* ![osx with ldc](https://badges.herokuapp.com/travis/FilipMalczak/glue-d?branch=dev&env=CI_CONTEXT=osx_ldc&label=OSX%20with%20ldc)

 
## ToDo
 
> __bold__ are WIP and highest prio
 
* conceptual
  * __figure out packaging__ - there are different qualifiers for source sets, they
    will probably be non-empty for libraries
    * figure out how to compose application from annotations pointing to scannables
    * figure out naming - what is library, what is "bundle"/"starter", etc; 
      we need some abstraction of library you depend on, add an annotation and
      autoconfiguration (scanning, defaults, etc) 
* new features
  * @PostConstruct methods
  * annotations enhancements:
    * validation (missing method/field/etc, only known Targets are types; 
      validations here are "has (no) parameter of type/name", "name matches" 
      with syntax sugar for "name starts/ends with")
    * @InheritAnnotations(target=aggregate/method/field) - if present, look into 
      superclasses and copy annotations from super 
  * __enhanced resolveCall and friends__
    * @Param(i/name, annotations...) - repeatable, used to define param-level annotations
    * @Seed on non-config method? (that would probably require either merging 
      dejector to this repo, duplicating resolveCall here or moving seed, 
      the whole annotations module and probably some annotation definitions there)
  * environment (string/string key-value pairs)
    * data is already gathered, but whats left is...
    * injection with @Config with support for simple types
  * value registry (environment required)
    * config inspection
    * autobinding structs/enums/simple types with @Value
  * indexing scanned classes (aliases/qualifiers in dejector will be useful, but
    not required; implementing in parallel will probably make API more consistent)
    * by stereotypes (with runtime-available stereotype instances)
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
