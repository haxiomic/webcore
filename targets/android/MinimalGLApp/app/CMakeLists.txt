cmake_minimum_required(VERSION 3.4.1)

# now build app's shared lib
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wall")

# Add the hxcpp generated lib
set(APP_PROJECT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/..)
set(HXCPP_BIN_DIR ${APP_PROJECT_DIR}/../_hxcpp-bin)
set(LIB_SUFFIX ${ANDROID_ABI})

add_library(MinimalGL STATIC IMPORTED)
set_target_properties(MinimalGL PROPERTIES IMPORTED_LOCATION ${HXCPP_BIN_DIR}/libMinimalGL-${LIB_SUFFIX}.a)

# To use the generated lib, we need to use a Java Native Interface wrapper
add_library(
    MinimalGLJNI SHARED
    src/main/cpp/MinimalGLJNI.cpp
)
# Add the hxcpp generated include directory so we can call methods of the hxcpp generated lib
target_include_directories(
    MinimalGLJNI PRIVATE
    ${HXCPP_BIN_DIR}/include
)

# Link the JNI interface with our hxcpp library and android system libraries
target_link_libraries(
    MinimalGLJNI
    # Hxcpp generated
    MinimalGL
    # System libraries
    EGL
    GLESv2
    android
    log
)

