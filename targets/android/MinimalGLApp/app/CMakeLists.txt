# This CMake file does the following:
# - Trigger haxe to recompile the lib
# - Compiles the Java Native Interface wrapper that talks to the haxe native lib
# - Links the wrapper with the haxe native lib and the required system libraries

cmake_minimum_required(VERSION 3.10.2)

# Setup some variables to use later
set(HXCPP_LIB_NAME MinimalGL) # this should match `HAXE_OUTPUT_PART` in the hxml
set(PROJECT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/..)
set(HXCPP_BIN_DIR ${PROJECT_DIR}/../_hxcpp-bin)

# Hxcpp names architectures slightly differently to the Android build toolchain so here we map between them
if( ANDROID_ABI STREQUAL "armeabi-v7a" )
    set(HXCPP_LIB_SUFFIX "v7")
    set(HXCPP_ARCH "HXCPP_ARMV7")
elseif( ANDROID_ABI STREQUAL "arm64-v8a" )
    set(HXCPP_LIB_SUFFIX "64")
    set(HXCPP_ARCH "HXCPP_ARM64")
elseif( ANDROID_ABI STREQUAL "x86")
    set(HXCPP_LIB_SUFFIX "x86")
    set(HXCPP_ARCH "HXCPP_X86")
elseif( ANDROID_ABI STREQUAL "x86_64")
    set(HXCPP_LIB_SUFFIX "x86_64")
    set(HXCPP_ARCH "HXCPP_X86_64")
else()
    message(SEND_ERROR "Unknown ABI for HXCPP ${ANDROID_ABI}")
    set(HXCPP_LIB_SUFFIX ${ANDROID_ABI})
    set(HXCPP_ARCH "")
endif()

# This variable references the hxcpp generated lib file
set(HXCPP_LIB_FILENAME lib${HXCPP_LIB_NAME}-${HXCPP_LIB_SUFFIX}.a)

# Add the hxcpp bin directory to library search path
link_directories(${HXCPP_BIN_DIR})

# To tigger rebuild with haxe and hxcpp we create a custom file generation command and custom target
# then we add this target as a dependency of the main target
add_custom_command(
    OUTPUT ${HXCPP_LIB_FILENAME}
    COMMAND haxe -D ${HXCPP_ARCH} build-lib.hxml
    WORKING_DIRECTORY ${PROJECT_DIR}/..
    USES_TERMINAL
)
add_custom_target(
    CompileHaxeCode ALL
    DEPENDS ${HXCPP_LIB_FILENAME}
)

# To use the generated lib, we need to use a Java Native Interface wrapper (we can't just call C functions directly like Swift can)
# we create a new shared library to do this:
add_library(
    MinimalGLJNIWrapper SHARED
    src/main/cpp/MinimalGLJNI.cpp
)
# Make CompileHaxeCode get executed when building by adding it as a dependency
add_dependencies(MinimalGLJNIWrapper CompileHaxeCode)
# Add the hxcpp generated include directory so we can see methods of the hxcpp generated lib
target_include_directories(
    MinimalGLJNIWrapper PRIVATE
    ${HXCPP_BIN_DIR}/include
)
# Set compiler flags for building the wrapper
target_compile_options(
    MinimalGLJNIWrapper PRIVATE
    -std=c++11 -Wall
)
# Link the JNI interface with our hxcpp library and android system libraries
target_link_libraries(
    MinimalGLJNIWrapper
    # Hxcpp generated
    ${HXCPP_LIB_FILENAME}
    # System libraries
    EGL
    GLESv2
    android
    log
)