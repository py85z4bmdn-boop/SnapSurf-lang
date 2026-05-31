cmake_minimum_required(VERSION 3.20)

project(SnapSurf LANGUAGES NONE)

find_program(FASM_EXECUTABLE fasm REQUIRED)

set(SNAPSURF_ROOT_BUILD_DIR "${CMAKE_SOURCE_DIR}/build")
set(SNAPSURF_COMPILER_SOURCE "${CMAKE_SOURCE_DIR}/compiler/fasm/main.asm")
set(SNAPSURF_COMPILER_BIN "${SNAPSURF_ROOT_BUILD_DIR}/surf")

file(GLOB_RECURSE SNAPSURF_FASM_SOURCES CONFIGURE_DEPENDS
    "${CMAKE_SOURCE_DIR}/compiler/fasm/*.asm"
    "${CMAKE_SOURCE_DIR}/compiler/fasm/*.inc"
)

add_custom_command(
    OUTPUT "${SNAPSURF_COMPILER_BIN}"
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${SNAPSURF_ROOT_BUILD_DIR}"
    COMMAND "${FASM_EXECUTABLE}" "${SNAPSURF_COMPILER_SOURCE}" "${SNAPSURF_COMPILER_BIN}"
    DEPENDS ${SNAPSURF_FASM_SOURCES}
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    COMMENT "Assembling SnapSurf compiler with FASM"
    VERBATIM
)

add_custom_target(surf ALL
    DEPENDS "${SNAPSURF_COMPILER_BIN}"
)

add_custom_target(fasm-smoke
    COMMAND "${SNAPSURF_COMPILER_BIN}" version
    DEPENDS surf
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
)

add_custom_target(check-discovery
    COMMAND sh -c "set +e; out=$(./build/surf check examples/hello 2>&1); code=$?; printf '%s\\n' \"$out\"; test \"$code\" = 0 && test \"$out\" = 'check ok'"
    COMMAND sh -c "set +e; out=$(./build/surf check tests/compile_fail/missing_pkg 2>&1); code=$?; printf '%s\\n' \"$out\"; test \"$code\" = 1 && test \"$out\" = 'tests/compile_fail/missing_pkg/surf.pkg:1:1 E0901 surf.pkg not found'"
    COMMAND sh -c "set +e; out=$(./build/surf check tests/compile_fail/missing_main 2>&1); code=$?; printf '%s\\n' \"$out\"; test \"$code\" = 1 && test \"$out\" = 'tests/compile_fail/missing_main/src/main.snapsurf:1:1 E0906 executable package requires src/main.snapsurf'"
    DEPENDS surf
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    VERBATIM
)

add_custom_target(full-regression
    COMMAND sh tests/run_all.sh
    DEPENDS surf
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
)
