#!/bin/bash

export CFLAGS="${DEBUG_CFLAGS//-Wall -Wextra/}"
export FFLAGS="${DEBUG_FFLAGS//-Wall -Wextra/}"

# Fix ctest not automatically discovering tests
LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,--gc-sections//g")

# See this workaround
# ( https://github.com/xianyi/OpenBLAS/issues/818#issuecomment-207365134 ).
CF="${CFLAGS}"
unset CFLAGS

if [[ "$PKG_VERSION" == "0.3.11" ]]; then
    # see https://github.com/xianyi/OpenBLAS/pull/2909
    sed -i.bak 's/$(BUILD_COMPLEX16)> $(@F)/$(BUILD_COMPLEX16) > $(@F)/g' exports/Makefile
fi

if [[ "$USE_OPENMP" == "1" ]]; then
    # Run the the fork test
    sed -i.bak 's/test_potrs.o/test_potrs.o test_fork.o/g' utest/Makefile
fi

if [ ! -z "$FFLAGS" ]; then
    export FFLAGS="${FFLAGS/-fopenmp/ }";
fi
export FFLAGS="${FFLAGS} -frecursive"

# Because -Wno-missing-include-dirs does not work with gfortran:
[[ -d "${PREFIX}"/include ]] || mkdir "${PREFIX}"/include
[[ -d "${PREFIX}"/lib ]] || mkdir "${PREFIX}"/lib

DEBUG=0
# Set CPU Target
if [[ "${target_platform}" == linux-aarch64 ]]; then
  TARGET="ARMV8"
  BINARY="64"
elif [[ "${target_platform}" == linux-ppc64le ]]; then
  TARGET="POWER8"
  BINARY="64"
elif [[ "${target_platform}" == linux-64 ]]; then
  TARGET="PRESCOTT"
  BINARY="64"
elif [[ "${target_platform}" == osx-64 ]]; then
  TARGET="CORE2"
  BINARY="64"
  DEBUG=1
elif [[ "${target_platform}" == osx-arm64 ]]; then
  TARGET="VORTEX"
  BINARY="64"
fi

QUIET_MAKE=0
if [[ "$CI" == "travis" ]]; then
  QUIET_MAKE=1
fi

export HOSTCC=$CC_FOR_BUILD

# Build all CPU targets and allow dynamic configuration
# Build LAPACK.
# Enable threading. This can be controlled to a certain number by
# setting OPENBLAS_NUM_THREADS before loading the library.
# Tests are run as part of build
make QUIET_MAKE=${QUIET_MAKE} DYNAMIC_ARCH=1 BINARY=${BINARY} NO_LAPACK=0 CFLAGS="${CF}" \
     HOST=${HOST} TARGET=${TARGET} CROSS_SUFFIX="${HOST}-" \
     NO_AFFINITY=1 USE_THREAD=1 NUM_THREADS=128 USE_OPENMP="${USE_OPENMP}" \
     INTERFACE64=${INTERFACE64} SYMBOLSUFFIX=${SYMBOLSUFFIX} DEBUG=${DEBUG}
make install PREFIX="${PREFIX}"
