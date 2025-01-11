#!/bin/bash

export BINUTILSVER=2.36.1
export BINUTILSREV=
export GCCVER=10.4.0
export GCCREV=
export NEWLIBVER=4.1.0
export NEWLIBREV=
export MPCVER=1.2.1
export MPCREV=
export MPFRVER=4.1.0
export MPFRREV=
export GMPVER=6.2.1
export GMPREV=

export GDBVER=
#export GDBVER=14.2
export GDBREV=

export ENABLE_BOOTSTRAP=0
export ENABLE_DOWNLOAD_CACHE=1
export ENABLE_STATIC_BUILD=0

exec "$@"
