mkdir build
cd build

cmake -G "NMake Makefiles JOM" ^
    -DCMAKE_CXX_COMPILER=clang-cl           ^
    -DCMAKE_C_COMPILER=clang-cl             ^
    -DCMAKE_Fortran_COMPILER=flang          ^
    -DCMAKE_BUILD_TYPE=Release              ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
    -DDYNAMIC_ARCH=ON                       ^
    -DBUILD_WITHOUT_LAPACK=no               ^
    -DNOFORTRAN=0                           ^
    ..

cmake --build . --target install
utest\openblas_utest.exe

