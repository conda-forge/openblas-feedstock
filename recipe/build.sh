#!/bin/bash

# https://github.com/xianyi/OpenBLAS/wiki/faq#Linux_SEGFAULT
patch < segfaults.patch

# See this workaround
# ( https://github.com/xianyi/OpenBLAS/issues/818#issuecomment-207365134 ).
CF="${CFLAGS}"
unset CFLAGS

# Fix ctest not automatically discovering tests
LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,--gc-sections//g")

# silly if statement but makes things clear
if [[ "${target_platform}" == "osx-64" ]]; then
    USE_OPENMP="1"
elif [[ "${target_platform}" == "linux-aarch64" ]]; then
    # Gnu OpenMP is not fork-safe and we do not have llvm OpenMP
    USE_OPENMP="0"
else
    # We will have to build with GNU and then use LLVM on run
    USE_OPENMP="1"
fi

if [[ "$USE_OPENMP" == "1" ]]; then
    # Run the the fork test
    sed -i.bak 's/test_potrs.o/test_potrs.o test_fork.o/g' utest/Makefile
fi

if [ ! -z "$FFLAGS" ]; then
    export FFLAGS="${FFLAGS/-fopenmp/ }";
fi

# Because -Wno-missing-include-dirs does not work with gfortran:
[[ -d "${PREFIX}"/include ]] || mkdir "${PREFIX}"/include
[[ -d "${PREFIX}"/lib ]] || mkdir "${PREFIX}"/lib

# USE_SIMPLE_THREADED_LEVEL3 is necessary to avoid hangs when more than one process uses blas:
#    https://github.com/xianyi/OpenBLAS/issues/1456
#    https://github.com/xianyi/OpenBLAS/issues/294
#    https://github.com/scikit-learn/scikit-learn/issues/636

# Set CPU Target
TARGET=""
if [[ ${target_platform} == linux-aarch64 ]]; then
  TARGET="TARGET=ARMV8"
fi
if [[ ${target_platform} == linux-ppc64le ]]; then
  TARGET="TARGET=POWER8"
fi

# Build all CPU targets and allow dynamic configuration
# Build LAPACK.
# Enable threading. This can be controlled to a certain number by
# setting OPENBLAS_NUM_THREADS before loading the library.
# Tests are run as part of build
make QUIET_MAKE=1 DYNAMIC_ARCH=1 BINARY=${ARCH} NO_LAPACK=0 NO_AFFINITY=1 USE_THREAD=1 NUM_THREADS=128 \
     USE_OPENMP="${USE_OPENMP}" USE_SIMPLE_THREADED_LEVEL3=1 CFLAGS="${CF}" FFLAGS="${FFLAGS} -frecursive" \
     INTERFACE64=${INTERFACE64} SYMBOLSUFFIX=${SYMBOLSUFFIX} HOST=${HOST} $TARGET CROSS_SUFFIX="${HOST}-"
make install PREFIX="${PREFIX}"
