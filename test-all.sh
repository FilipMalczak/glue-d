#!/bin/bash
#not used in CI, but handy for development

if [ -z "$DC" ]
then
    CONFIG=""
else
    CONFIG="--compiler=${DC}"
fi

set -ex

dub test glue-d:utils $CONFIG
dub test glue-d:logging $CONFIG
dub test glue-d:annotations $CONFIG
#indexer is tested in main module
dub run --config=indexer $CONFIG
dub test $CONFIG
