cmake_minimum_required(VERSION 2.8.9)

project(RANC_Simulator)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -ggdb")

include_directories(extern)

file(GLOB SOURCES "src/*.cpp")

add_executable(ranc_sim ${SOURCES})