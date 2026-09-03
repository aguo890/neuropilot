cmake_minimum_required(VERSION 3.16)
project(neuropilot_core VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Optimization and warning flags
if(MSVC)
    add_compile_options(/W4 /O2)
else()
    add_compile_options(-Wall -Wextra -pedantic -O3)
endif()

# Core static library
add_library(neuropilot_core STATIC
    src/matrix.cpp
    src/kalman_filter.cpp
)

target_include_directories(neuropilot_core PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

# Test executable
add_executable(test_kalman
    tests/test_kalman.cpp
)

target_link_libraries(test_kalman PRIVATE neuropilot_core)

enable_testing()
add_test(NAME KalmanFilterTests COMMAND test_kalman)
