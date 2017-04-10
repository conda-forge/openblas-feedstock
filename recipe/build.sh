#!/bin/bash

# See this workaround
# ( https://github.com/xianyi/OpenBLAS/issues/818#issuecomment-207365134 ).
CF="${CFLAGS}"
unset CFLAGS

if [[ `uname` == 'Darwin' ]]; then
     export LIBRARY_SEARCH_VAR=DYLD_FALLBACK_LIBRARY_PATH
else
     export LIBRARY_SEARCH_VAR=LD_LIBRARY_PATH
fi
eval export ${LIBRARY_SEARCH_VAR}="${PREFIX}/lib"

# Build all CPU targets and allow dynamic configuration
# Build LAPACK.
# Enable threading. This can be controlled to a certain number by
# setting OPENBLAS_NUM_THREADS before loading the library.
make QUIET_MAKE=1 DYNAMIC_ARCH=1 BINARY=${ARCH} NO_LAPACK=0 NO_AFFINITY=1 USE_THREAD=1 CFLAGS="${CF}" FFLAGS="-frecursive"
# Fix paths to ensure they have the $PREFIX in them.
if [[ `uname` == 'Darwin' ]]; then
    for OPENBLAS_LIB in $( find "${PREFIX}/lib" -name "libopenblas*.dylib" ); do
        install_name_tool -change \
                @rpath/./libgfortran.3.dylib \
                "${PREFIX}/lib/libgfortran.3.dylib" \
                "${OPENBLAS_LIB}"
        install_name_tool -change \
                @rpath/./libquadmath.0.dylib \
                "${PREFIX}/lib/libquadmath.0.dylib" \
                "${OPENBLAS_LIB}"
        install_name_tool -change \
                @rpath/./libgcc_s.1.dylib \
                "${PREFIX}/lib/libgcc_s.1.dylib" \
                "${OPENBLAS_LIB}"
    done
fi
OPENBLAS_NUM_THREADS=$CPU_COUNT make test
make install PREFIX="${PREFIX}"

# As OpenBLAS, now will have all symbols that BLAS or LAPACK have,
# create libraries with the standard names that are linked back to
# OpenBLAS. This will make it easier for packages that are looking for them.
ln -fs $PREFIX/lib/libopenblas.a $PREFIX/lib/libblas.a
ln -fs $PREFIX/lib/libopenblas.a $PREFIX/lib/liblapack.a
ln -fs $PREFIX/lib/libopenblas$SHLIB_EXT $PREFIX/lib/libblas$SHLIB_EXT
ln -fs $PREFIX/lib/libopenblas$SHLIB_EXT $PREFIX/lib/liblapack$SHLIB_EXT
