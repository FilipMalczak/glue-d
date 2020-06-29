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

dub test glue-d:context $CONFIG

# codescan uses custom test qualifier
dub run glue-d:codescan --config=indexer
dub test glue-d:codescan $CONFIG

# main module uses default qualifiers
dub run --config=indexer $CONFIG
dub test $CONFIG
