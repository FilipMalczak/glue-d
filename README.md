# glue-d

> master: [master status](https://img.shields.io/travis/FilipMalczak/glue-d?label=master)](https://travis-ci.org/FilipMalczak/glue-d/branches)
>
> dev: [![dev status](https://travis-ci.org/FilipMalczak/glue-d.svg?branch=dev)](https://travis-ci.org/FilipMalczak/glue-d/branches)

Bunch of different D-lang tools glued together with some sprinkles on top.

The point is to implement autoscanning, implement some annotation system (both done)
then glue together a bunch of other projects: forked dejector for DI, mirror for
reflection. Together with that this will become full application context, with
runtime features, like autowiring, inheritance inspection and instantiation, as 
well as compile-time component scan, stereotyping, auto-implementation of interfaces,
etc.

Next integrations will probably include vibe-d and maybe some data drivers.

Heavily inspired by Spring.
