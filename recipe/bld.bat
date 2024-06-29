@echo on

:: show CPU arch to detect slow CI agents early (rather than wait for 6h timeout)
python -c "import numpy; numpy.show_config()"

:: flang still uses a temporary name not recognized by CMake
copy %BUILD_PREFIX%\Library\bin\flang-new.exe %BUILD_PREFIX%\Library\bin\flang.exe

mkdir build
cd build

:: millions of lines of warnings with clang-19
set "CFLAGS=%CFLAGS% -w"

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
    -DUSE_OPENMP=%USE_OPENMP%               ^
    %SRC_DIR%
if %ERRORLEVEL% neq 0 exit 1

cmake --build . --target install
if %ERRORLEVEL% neq 0 exit 1

ctest -j2
if %ERRORLEVEL% neq 0 exit 1
