cmake_minimum_required(VERSION 3.25)
project(myutils)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(HAKATIME OFF)
option(NIRIUSE ON)

# ╭──────────────────────────────────────╮
# │                 CPM                  │
# ╰──────────────────────────────────────╯
set(CPM_FILE ${CMAKE_BINARY_DIR}/CPM.cmake)
set(CPM_VERSION "0.42.0")
if(NOT EXISTS "${CPM_FILE}")
    file(DOWNLOAD "https://github.com/cpm-cmake/CPM.cmake/releases/download/v${CPM_VERSION}/CPM.cmake" ${CPM_FILE})
endif()
include(${CPM_FILE})

# ╭──────────────────────────────────────╮
# │               NIRIUSE                │
# ╰──────────────────────────────────────╯
cpmaddpackage("gh:nlohmann/json@3.12.0")
add_executable(niriuse niriuse.cpp)
target_link_libraries(niriuse PRIVATE nlohmann_json)
