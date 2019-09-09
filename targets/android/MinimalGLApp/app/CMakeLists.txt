cmake_minimum_required(VERSION 3.4.1)

# now build app's shared lib
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wall")

set(APP_PROJECT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/..)
set(HXCPP_BIN_DIR ${APP_PROJECT_DIR}/../_hxcpp-bin)

add_library(MinimalGL STATIC IMPORTED)
set_target_properties(MinimalGL PROPERTIES IMPORTED_LOCATION ${HXCPP_BIN_DIR}/libMinimalGL-${ANDROID_ABI}.a)

add_library(
    gl2jni SHARED
    src/main/cpp/gl_code.cpp
)

# add lib dependencies
target_link_libraries(
    gl2jni
    MinimalGL
    android
    log 
    EGL
    GLESv2
)

