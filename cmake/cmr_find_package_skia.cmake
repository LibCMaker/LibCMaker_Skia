# ****************************************************************************
#  Project:  LibCMaker
#  Purpose:  A CMake build scripts for build libraries with CMake
#  Author:   NikitaFeodonit, nfeodonit@yandex.com
# ****************************************************************************
#    Copyright (c) 2017-2022 NikitaFeodonit
#
#    This file is part of the LibCMaker project.
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published
#    by the Free Software Foundation, either version 3 of the License,
#    or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#    See the GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program. If not, see <http://www.gnu.org/licenses/>.
# ****************************************************************************

# Part of "LibCMaker/cmake/cmr_find_package.cmake".

  #-----------------------------------------------------------------------
  # Library specific build arguments
  #-----------------------------------------------------------------------

## +++ Common part of the lib_cmaker_<lib_name> function +++
  set(find_LIB_VARS
    is_official_build
    is_debug
    is_skia_standalone
    is_skia_dev_build
    is_component_build
    skia_use_ndk_images
    skia_enable_api_available_macro
    skia_use_system_expat
    skia_use_system_freetype2
    skia_use_system_harfbuzz
    skia_use_system_icu
    skia_use_system_libjpeg_turbo
    skia_use_system_libpng
    skia_use_system_libwebp
    skia_use_system_zlib
    skia_use_expat
    skia_use_freetype
    skia_use_freetype_woff2
    skia_use_harfbuzz
    skia_use_icu
    skia_use_runtime_icu
    skia_use_sfntly
    skia_use_libjpeg_turbo_decode
    skia_use_libjpeg_turbo_encode
    skia_use_libpng_decode
    skia_use_libpng_encode
    skia_use_libwebp_decode
    skia_use_libwebp_encode
    skia_use_piex
    skia_use_zlib
    skia_enable_gpu
    skia_enable_discrete_gpu
    skia_use_angle
    skia_use_dawn
    skia_use_direct3d
    skia_use_egl
    skia_use_gl
    skia_use_metal
    skia_use_x11
    skia_use_vulkan
    skia_enable_sksl
    skia_enable_skgpu_v1
    skia_enable_graphite
    skia_use_ffmpeg
    skia_use_sfml
    skia_use_wuffs
    skia_use_xps
    skia_use_libgifcodec
    skia_enable_tools
    skia_enable_android_utils
    skia_enable_direct3d_debug_layer
    skia_enable_gpu_debug_layers
    skia_enable_metal_debug_info
    skia_enable_skvm_jit_when_possible
    skia_enable_spirv_validation
    skia_enable_vulkan_debug_layers
    skia_use_libheif
    skia_use_lua
    skia_use_fontconfig
    skia_enable_fontmgr_android
    skia_enable_fontmgr_fontconfig
    skia_enable_fontmgr_FontConfigInterface
    skia_use_fonthost_mac
    skia_enable_fontmgr_win_gdi
    skia_use_dng_sdk
    skia_enable_particles
    skia_enable_skshaper
    skia_enable_skottie
    skia_enable_svg
    skia_enable_skparagraph
    paragraph_gms_enabled
    paragraph_tests_enabled
    paragraph_bench_enabled
    skia_enable_sktext
    text_gms_enabled
    text_tests_enabled
    text_bench_enabled
    skia_enable_pdf
    skia_pdf_subset_harfbuzz
    skia_enable_skrive
    skia_use_fixed_gamma_text
    skia_enable_winuwp
  )

  foreach(d ${find_LIB_VARS})
    if(DEFINED ${d})
      list(APPEND find_CMAKE_ARGS
        -D${d}=${${d}}
      )
    endif()
  endforeach()
## --- Common part of the lib_cmaker_<lib_name> function ---


  #-----------------------------------------------------------------------
  # Building
  #-----------------------------------------------------------------------

## +++ Common part of the lib_cmaker_<lib_name> function +++
  cmr_lib_cmaker_main(
    LibCMaker_DIR ${find_LibCMaker_DIR}
    NAME          ${find_NAME}
    VERSION       ${find_VERSION}
    LANGUAGES     CXX C
    BASE_DIR      ${find_LIB_DIR}
    DOWNLOAD_DIR  ${cmr_DOWNLOAD_DIR}
    UNPACKED_DIR  ${cmr_UNPACKED_DIR}
    BUILD_DIR     ${lib_BUILD_DIR}
    CMAKE_ARGS    ${find_CMAKE_ARGS}
    INSTALL
  )
## --- Common part of the lib_cmaker_<lib_name> function ---
