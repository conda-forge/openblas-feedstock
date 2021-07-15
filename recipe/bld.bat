mkdir build
cd build

cmake -G "NMake Makefiles JOM"              ^
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
if %ERRORLEVEL% neq 0 exit 1

jom install -j%CPU_COUNT%
if %ERRORLEVEL% neq 0 exit 1

utest\openblas_utest.exe
if %ERRORLEVEL% neq 0 exit 1
