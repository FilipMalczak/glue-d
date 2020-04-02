#!/bin/bash

set -ex

rm ./source/**/*_index.d
rm ./test/**/*_index.d

dub clean
