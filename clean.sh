#!/bin/bash

set -x

find . -name "*.lst" -type f -delete
find . \( -name "*_index.d" ! -name "generate_index.d" \) -type f -delete
find . -name "*_bundle.d" -type f -delete

dub clean
cd ./annotations && dub clean
cd ../codescan && dub clean
cd ../context && dub clean
cd ../indexer && dub clean
cd ../logging && dub clean
cd ../utils && dub clean
