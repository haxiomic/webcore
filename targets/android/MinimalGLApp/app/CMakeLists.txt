# This CMake file does the following:
# - Trigger haxe to recompile the lib
# - Compiles the Java Native Interface wrapper that talks to the haxe native lib
# - Links the wrapper with the haxe native lib and the required system libraries

cmake_minimum_required(VERSION 3.4.1)

# Setup some variables to use later
set(HXCPP_LIB_NAME MinimalGL)
set(APP_PROJECT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/..)
set(HXCPP_BIN_DIR ${APP_PROJECT_DIR}/../_hxcpp-bin)

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
set(HXCPP_LIB_FILE ${HXCPP_BIN_DIR}/lib${HXCPP_LIB_NAME}-${HXCPP_LIB_SUFFIX}.a)

# Tigger rebuild with hxcpp
execute_process(
    WORKING_DIRECTORY ${APP_PROJECT_DIR}/..
    COMMAND haxe -D ${HXCPP_ARCH} build-lib.hxml 
)

# Add the hxcpp generated lib file as a static library
add_library(HxcppLib STATIC IMPORTED GLOBAL)
set_target_properties(HxcppLib PROPERTIES IMPORTED_LOCATION ${HXCPP_LIB_FILE})

# To use the generated lib, we need to use a Java Native Interface wrapper
# We create a new shared library to do this
add_library(
    MinimalGLJNIWrapper SHARED
    src/main/cpp/MinimalGLJNI.cpp
)
# Add the hxcpp generated include directory so we can call methods of the hxcpp generated lib
target_include_directories(
    MinimalGLJNIWrapper PRIVATE
    ${HXCPP_BIN_DIR}/include
)
# Set flags for building the wrapper
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wall")

# Link the JNI interface with our hxcpp library and android system libraries
target_link_libraries(
    MinimalGLJNIWrapper
    # Hxcpp generated
    HxcppLib
    # System libraries
    EGL
    GLESv2
    android
    log
)