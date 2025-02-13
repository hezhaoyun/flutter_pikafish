cmake_minimum_required(VERSION 3.4.1)

file(GLOB_RECURSE cppPaths "../ios/Pikafish/src/*.cpp")
add_library(
  pikafish
  SHARED
  ../ios/FlutterPikafish/ffi.cpp
  ${cppPaths}
)

if(ANDROID_ABI STREQUAL arm64-v8a)
  if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_options(pikafish PRIVATE -DUSE_PTHREADS -DIS_64BIT -DUSE_POPCNT -DUSE_NEON=8)
  else()
    target_compile_options(pikafish PRIVATE -fno-exceptions -DUSE_PTHREADS -DNDEBUG -O3 -DIS_64BIT -DUSE_POPCNT -DUSE_NEON=8)
  endif()
else()
  if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_options(pikafish PRIVATE -DUSE_PTHREADS)
  else()
    target_compile_options(pikafish PRIVATE -fno-exceptions -DUSE_PTHREADS -DNDEBUG -O3)
  endif()
endif()

file(DOWNLOAD https://tests.pikafishchess.org/api/nn/nn-5af11540bbfe.nnue ${CMAKE_BINARY_DIR}/nn-5af11540bbfe.nnue)
