#!/bin/sh

./clean.sh
dub run --config=indexer
./test-all.sh
