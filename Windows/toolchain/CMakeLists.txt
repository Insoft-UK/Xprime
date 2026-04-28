cmake_minimum_required(VERSION 3.25)

project(XprimeToolchain LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

get_filename_component(XPRIME_ROOT "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE)
set(HPPPL_ROOT "${XPRIME_ROOT}/Xcode/Tools/hpppl+")
set(HPNOTE_ROOT "${XPRIME_ROOT}/Xcode/Tools/hpnote")

function(xprime_common target)
    target_compile_features(${target} PRIVATE cxx_std_23)
    target_compile_definitions(${target} PRIVATE
        NOMINMAX
        WIN32_LEAN_AND_MEAN
    )

    if(MINGW)
        target_compile_options(${target} PRIVATE -Wall -Wextra)
    elseif(MSVC)
        target_compile_options(${target} PRIVATE /W4 /permissive-)
    endif()
endfunction()

file(GLOB HPPPLPLUS_SOURCES CONFIGURE_DEPENDS
    "${HPPPL_ROOT}/src/*.cpp"
    "${HPPPL_ROOT}/src/libhpppl/src/*.cpp"
    "${HPPPL_ROOT}/src/libhpprgm/src/*.cpp"
    "${HPPPL_ROOT}/src/libmin/src/*.cpp"
    "${HPPPL_ROOT}/src/librfmt/src/*.cpp"
)

add_executable(hppplplus ${HPPPLPLUS_SOURCES})
set_target_properties(hppplplus PROPERTIES OUTPUT_NAME "hppplplus")
target_include_directories(hppplplus PRIVATE
    "${HPPPL_ROOT}/src"
    "${HPPPL_ROOT}/src/libhpppl/include"
    "${HPPPL_ROOT}/src/libhpprgm/include"
    "${HPPPL_ROOT}/src/libmin/include"
    "${HPPPL_ROOT}/src/librfmt/include"
)
xprime_common(hppplplus)

file(GLOB HPNOTE_SOURCES CONFIGURE_DEPENDS
    "${HPNOTE_ROOT}/src/*.cpp"
)

add_executable(hpnote ${HPNOTE_SOURCES})
target_include_directories(hpnote PRIVATE "${HPNOTE_ROOT}/src")
xprime_common(hpnote)

set(FONT_ROOT "${HPPPL_ROOT}/add-ons/font")
file(GLOB FONT_SOURCES CONFIGURE_DEPENDS
    "${FONT_ROOT}/src/*.cpp"
)

add_executable(font ${FONT_SOURCES})
target_include_directories(font PRIVATE "${FONT_ROOT}/src")
xprime_common(font)

set(GROB_ROOT "${HPPPL_ROOT}/add-ons/grob")
find_package(PNG QUIET)
find_package(ZLIB QUIET)

if(PNG_FOUND AND ZLIB_FOUND)
    file(GLOB GROB_SOURCES CONFIGURE_DEPENDS
        "${GROB_ROOT}/src/*.cpp"
        "${GROB_ROOT}/src/libhpprgm/src/*.cpp"
    )

    add_executable(grob ${GROB_SOURCES})
    target_include_directories(grob PRIVATE
        "${GROB_ROOT}/src"
        "${GROB_ROOT}/src/libhpprgm/include"
    )
    target_link_libraries(grob PRIVATE PNG::PNG ZLIB::ZLIB)
    xprime_common(grob)
else()
    message(WARNING "PNG/ZLIB were not found, so the grob image add-on target is not generated. Install them with vcpkg or MSYS2 and reconfigure.")
endif()

install(TARGETS hppplplus hpnote font
    RUNTIME DESTINATION tools/bin
)

if(TARGET grob)
    install(TARGETS grob RUNTIME DESTINATION tools/bin)
endif()
