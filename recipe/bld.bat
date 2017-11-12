mkdir build
cd build
if "%ARCH%" == "64" (
    set OPENBLAS_ARCH=x86_64
) ELSE (
    set OPENBLAS_ARCH=x86
)

conda install -c isuruf/label/flang cmake

cmake -G "NMake Makefiles" ^
    -DCMAKE_CXX_COMPILER=clang-cl ^
    -DCMAKE_C_COMPILER=clang-cl ^
    -DCMAKE_Fortran_COMPILER=flang ^
    -DBUILD_WITHOUT_LAPACK=no ^
    -DNOFORTRAN=0 ^
    -DDYNAMIC_ARCH=ON ^
    ..

cmake --build . --target install -- -j%CPU_COUNT%
utest\openblas_utest.exe

move ../INCLUDE/*.h %LIBRARY_INC%

