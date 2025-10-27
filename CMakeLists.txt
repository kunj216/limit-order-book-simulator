cmake_minimum_required(VERSION 3.16)
project(lob_simulator VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(LOB_BUILD_TESTS "Build unit tests" ON)
option(LOB_BUILD_BENCHMARKS "Build microbenchmarks" OFF)
option(LOB_BUILD_PYTHON "Build pybind11 module" OFF)

add_library(lob_core STATIC
    src/order_book.cpp
    src/matching_engine.cpp
    src/analytics.cpp
    src/simulator.cpp
)
target_include_directories(lob_core
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)
target_compile_features(lob_core PUBLIC cxx_std_20)

add_executable(lob_simulator src/main.cpp)
target_link_libraries(lob_simulator PRIVATE lob_core)

if (LOB_BUILD_TESTS)
    enable_testing()
    add_executable(lob_tests
        tests/catch_amalgamated.cpp
        tests/test_order_book.cpp
    )
    target_link_libraries(lob_tests PRIVATE lob_core)
    target_include_directories(lob_tests PRIVATE tests)
    add_test(NAME lob_tests COMMAND lob_tests)
endif ()

if (LOB_BUILD_BENCHMARKS)
    find_package(benchmark QUIET)
    if (benchmark_FOUND)
        add_executable(lob_bench benchmarks/order_book_benchmark.cpp)
        target_compile_definitions(lob_bench PRIVATE LOB_ENABLE_GOOGLE_BENCHMARK)
        target_link_libraries(lob_bench PRIVATE lob_core benchmark::benchmark)
    else ()
        message(WARNING "Google Benchmark not found; benchmarks will not be built.")
    endif ()
endif ()

if (LOB_BUILD_PYTHON)
    find_package(pybind11 CONFIG QUIET)
    if (pybind11_FOUND)
        pybind11_add_module(lob_cpp bindings/module.cpp)
        target_link_libraries(lob_cpp PRIVATE lob_core)
    else ()
        message(WARNING "pybind11 not found; skipping Python bindings.")
    endif ()
endif ()
