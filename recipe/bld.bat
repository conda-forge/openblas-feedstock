mkdir build
cd build

cmake -G "Ninja"                            ^
    -DCMAKE_C_COMPILER=clang-cl             ^
    -DCMAKE_Fortran_COMPILER=flang          ^
    -DCMAKE_BUILD_TYPE=Release              ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
    -DDYNAMIC_ARCH=ON                       ^
    -DBUILD_WITHOUT_LAPACK=no               ^
    -DNOFORTRAN=0                           ^
    -DNUM_THREADS=128                       ^
    -DBUILD_SHARED_LIBS=on                  ^
    %SRC_DIR%

if defined USE_OPENMP (
  cmake -DUSE_OPENMP %SRC_DIR%
)

cmake --build . --target install

utest\openblas_utest.exe
