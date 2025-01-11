#!/bin/bash

export BINUTILSVER=2.41
export BINUTILSREV=
export GCCVER=12.3.0
export GCCREV=
export NEWLIBVER=4.3.0
export NEWLIBREV=
export MPCVER=1.3.1
export MPCREV=
export MPFRVER=4.2.1
export MPFRREV=
export GMPVER=6.3.0
export GMPREV=
export GDBVER=
#export GDBVER=14.2
export GDBREV=

export ENABLE_BOOTSTRAP=0
export ENABLE_DOWNLOAD_CACHE=0
export ENABLE_STATIC_BUILD=0

exec "$@"
