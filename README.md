# glue-d

[![Build Status](https://travis-ci.org/FilipMalczak/glue-d.svg?branch=master)](https://travis-ci.org/FilipMalczak/glue-d)

Bunch of different D-lang tools glued together with some sprinkles on top.

The point is to implement autoscanning, implement some annotation system (both done)
then glue together a bunch of other projects: forked dejector for DI, mirror for
reflection. Together with that this will become full application context, with
runtime features, like autowiring, inheritance inspection and instantiation, as 
well as compile-time component scan, stereotyping, auto-implementation of interfaces,
etc.

Next integrations will probably include vibe-d and maybe some data drivers.

Heavily inspired by Spring.
