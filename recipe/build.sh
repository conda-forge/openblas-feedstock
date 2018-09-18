#!/bin/bash

set -e
# Stuart's recommendation to stop lapack-test from failing
ulimit -s 50000

# https://github.com/xianyi/OpenBLAS/wiki/faq#Linux_SEGFAULT
patch < segfaults.patch

# See this workaround
# ( https://github.com/xianyi/OpenBLAS/issues/818#issuecomment-207365134 ).
export CF="${CPPFLAGS} ${CFLAGS} -Wno-unused-parameter -Wno-old-style-declaration"
unset CFLAGS
export LAPACK_FFLAGS="${FFLAGS}"

# no openmp on mac.  We're mixing gfortran with clang, and they each have their own openmp.
if [[ ${target_platform} == osx-64 ]]; then
    USE_OPENMP="0"
    export CF="$CF -Wl,-rpath,$PREFIX/lib"
    export LAPACK_FFLAGS="$LAPACK_FFLAGS -Wl,-rpath,$PREFIX/lib"
    export FFLAGS="$FFLAGS -Wl,-rpath,$PREFIX/lib"
else
    # Gnu OpenMP is not fork-safe.  We disable openmp right now, so that downstream packages don't hang as a result of this.
    # USE_OPENMP="1"
    USE_OPENMP="0"
fi

# Build all CPU targets and allow dynamic configuration
# Build LAPACK.
# Enable threading. This can be controlled to a certain number by
# setting OPENBLAS_NUM_THREADS before loading the library.
# Because -Wno-missing-include-dirs does not work with gfortran:
[[ -d "${PREFIX}"/include ]] || mkdir "${PREFIX}"/include

# USE_SIMPLE_THREADED_LEVEL3 is necessary to avoid hangs when more than one process uses blas:
#    https://github.com/xianyi/OpenBLAS/issues/1456
#    https://github.com/xianyi/OpenBLAS/issues/294
#    https://github.com/scikit-learn/scikit-learn/issues/636

make DYNAMIC_ARCH=1 BINARY=${ARCH} NO_LAPACK=0 NO_AFFINITY=1 USE_THREAD=1 NUM_THREADS=128 \
     USE_OPENMP="${USE_OPENMP}" USE_SIMPLE_THREADED_LEVEL3=1 CFLAGS="${CF}" FFLAGS="${FFLAGS}"
OPENBLAS_NUM_THREADS=${CPU_COUNT} CFLAGS="${CF}" FFLAGS="${FFLAGS}" make test
OPENBLAS_NUM_THREADS=${CPU_COUNT} CFLAGS="${CF}" FFLAGS="${FFLAGS}" make lapack-test
CFLAGS="${CF}" FFLAGS="${FFLAGS}" make install PREFIX="${PREFIX}"

# As OpenBLAS, now will have all symbols that BLAS, CBLAS or LAPACK have,
# create libraries with the standard names that are linked back to
# OpenBLAS. This will make it easier for packages that are looking for them.
for arg in blas cblas lapack; do
  ln -fs "${PREFIX}"/lib/pkgconfig/openblas.pc "${PREFIX}"/lib/pkgconfig/$arg.pc
  ln -fs "${PREFIX}"/lib/libopenblas.a "${PREFIX}"/lib/lib$arg.a
  ln -fs "${PREFIX}"/lib/libopenblas$SHLIB_EXT "${PREFIX}"/lib/lib$arg$SHLIB_EXT
done

if [[ ${target_platform} == osx-64 ]]; then
  # Needs to fix the install name of the dylib so that the downstream projects will link
  # to libopenblas.dylib instead of libopenblasp-r0.2.20.dylib
  # In linux, SONAME is libopenblas.so.0 instead of libopenblasp-r0.2.20.so, so no change needed
  ${INSTALL_NAME_TOOL} -id "${PREFIX}"/lib/libopenblas.dylib "${PREFIX}"/lib/libopenblas.dylib
fi

cp "${RECIPE_DIR}"/site.cfg "${PREFIX}"/site.cfg
echo library_dirs = ${PREFIX}/lib >> "${PREFIX}"/site.cfg
echo include_dirs = ${PREFIX}/include >> "${PREFIX}"/site.cfg
echo runtime_include_dirs = ${PREFIX}/lib >> "${PREFIX}"/site.cfg
