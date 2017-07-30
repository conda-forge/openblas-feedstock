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
    -DCMAKE_BUILD_TYPE=Release              ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
    -DARCH=%OPENBLAS_ARCH%                  ^
    ..

cmake --build . --target install -- -j%CPU_COUNT%
utest\openblas_utest.exe

mkdir %SRC_DIR%\clapack
cd %SRC_DIR%\clapack
curl -L -o clapack-3.2.1-CMAKE.tgz http://uvcdat.llnl.gov/cdat/resources/clapack-3.2.1-CMAKE.tgz
7z x clapack-3.2.1-CMAKE.tgz
7z x clapack-3.2.1-CMAKE.tar

cd clapack-3.2.1-CMAKE
rm BLAS/CMakeLists.txt
rm SRC/CMakeLists.txt
rm CMakeLists.txt
cp %RECIPE_DIR%/clapack-blas-CMakeLists.txt BLAS/CMakeLists.txt
cp %RECIPE_DIR%/clapack-src-CMakeLists.txt SRC/CMakeLists.txt
cp %RECIPE_DIR%/clapack-CMakeLists.txt CMakeLists.txt

mkdir build
cd build

cmake -G "Ninja" ^
    -DCMAKE_CXX_COMPILER=clang-cl           ^
    -DCMAKE_C_COMPILER=clang-cl             ^
    -DCMAKE_BUILD_TYPE=Release              ^
    -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=on   ^
    -DARCH=%OPENBLAS_ARCH%                  ^
    ..

cmake --build . -- -j%CPU_COUNT%
cp SRC/lapack.lib %LIBRARY_LIB%/lapack.lib
cp SRC/lapack.dll %LIBRARY_BIN%/lapack.dll
move ../INCLUDE/*.h %LIBRARY_INC%

