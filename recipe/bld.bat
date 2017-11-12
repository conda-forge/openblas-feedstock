mkdir build
cd build
if "%ARCH%" == "64" (
    set OPENBLAS_ARCH=x86_64
) ELSE (
    set OPENBLAS_ARCH=x86
)
cmake -G "Ninja" ^
    -DCMAKE_CXX_COMPILER=clang-cl           ^
    -DCMAKE_C_COMPILER=clang-cl             ^
    -DCMAKE_Fortran_COMPILER=flang          ^
    -DCMAKE_BUILD_TYPE=Release              ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
    -DARCH=%OPENBLAS_ARCH%                  ^
    ..

cmake --build . --target install -- -j%CPU_COUNT%
utest\openblas_utest.exe

move ../INCLUDE/*.h %LIBRARY_INC%

