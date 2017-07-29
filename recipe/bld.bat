mkdir build
cd build
cmake -G "Ninja" -DCMAKE_CXX_COMPILER=clang-cl -DCMAKE_C_COMPILER=clang-cl -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% -DARCH=x86_64 ..
cmake --build . --target install
utest\openblas_utest.exe