cmake_minimum_required(VERSION 3.25)
project(myutils)


# ╭──────────────────────────────────────╮
# │               HakaTime               │
# ╰──────────────────────────────────────╯
find_package(PkgConfig REQUIRED)
pkg_check_modules(LIBSECRET REQUIRED IMPORTED_TARGET libsecret-1)

add_executable(hakatime hakatime.cpp)

target_link_libraries(hakatime PRIVATE PkgConfig::LIBSECRET)
target_include_directories(hakatime PRIVATE ${LIBSECRET_INCLUDE_DIRS})
target_link_libraries(hakatime PRIVATE ${LIBSECRET_LIBRARIES})
target_compile_options(hakatime PRIVATE ${LIBSECRET_CFLAGS_OTHER})

find_package(nlohmann_json REQUIRED)
target_link_libraries(hakatime PRIVATE nlohmann_json::nlohmann_json)

