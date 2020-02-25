#define STB_IMAGE_IMPLEMENTATION
#define STBI_NO_STDIO // disable filesystem io
#define STBI_NO_THREAD_LOCALS // not supported with haxe-iOS compiler setup
#include "./stb_image.h"