@echo on
SetLocal EnableDelayedExpansion

:: flang still uses a temporary name not recognized by CMake
copy %BUILD_PREFIX%\Library\bin\flang-new.exe %BUILD_PREFIX%\Library\bin\flang.exe

mkdir build
cd build

if "%USE_OPENMP%"=="1" (
    set "CMAKE_EXTRA=-DOpenMP_Fortran_FLAGS=-fopenmp -DOpenMP_Fortran_LIB_NAMES=libomp -DOpenMP_libomp_LIBRARY=-llibomp"
)

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
    !CMAKE_EXTRA!                           ^
    %SRC_DIR%
if %ERRORLEVEL% neq 0 exit 1

cmake --build . --target install
if %ERRORLEVEL% neq 0 exit 1

ctest -j2
if %ERRORLEVEL% neq 0 exit 1
