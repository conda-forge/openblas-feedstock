@echo on
SetLocal EnableDelayedExpansion

:: flang still uses a temporary name not recognized by CMake
copy %BUILD_PREFIX%\Library\bin\flang-new.exe %BUILD_PREFIX%\Library\bin\flang.exe

mkdir build
cd build

if "%USE_OPENMP%"=="1" (
    REM https://discourse.cmake.org/t/how-to-find-openmp-with-clang-on-macos/8860
    set "CMAKE_EXTRA=-DOpenMP_ROOT=%LIBRARY_LIB%"
    REM not picked up by `find_package(OpenMP)` for some reason
    set "CMAKE_EXTRA=-DOpenMP_Fortran_FLAGS=-fopenmp -DOpenMP_Fortran_LIB_NAMES=libomp"
)

:: millions of lines of warnings with clang-19
set "CFLAGS=%CFLAGS% -w"

cmake -G "Ninja"                            ^
    -DCMAKE_C_COMPILER=clang-cl             ^
    -DCMAKE_Fortran_COMPILER=flang          ^
    -DCMAKE_BUILD_TYPE=Release              ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
    -DDYNAMIC_ARCH=ON                       ^
    -DBUILD_WITHOUT_LAPACK=no               ^
    -DNO_AVX512=1                           ^
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
