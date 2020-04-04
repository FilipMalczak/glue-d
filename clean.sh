#!/bin/bash

set -x

rm ./source/**/*_index.d
rm ./test/**/*_index.d

rm ./source/**/**/*_index.d
rm ./test/**/**/*_index.d

dub clean
