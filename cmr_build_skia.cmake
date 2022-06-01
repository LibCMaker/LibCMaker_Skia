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

#-----------------------------------------------------------------------
# The file is an example of the convenient script for the library build.
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
# Lib's name, version, paths
#-----------------------------------------------------------------------

set(SKIA_lib_NAME "Skia")
set(SKIA_lib_VERSION "98" CACHE STRING "SKIA_lib_VERSION")
set(SKIA_lib_COMPONENTS
  skia skottie skparagraph sksg skshaper sktext skunicode
  CACHE STRING "SKIA_lib_COMPONENTS"
)
set(SKIA_lib_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE PATH "SKIA_lib_DIR")


# To use our Find<LibName>.cmake.
list(APPEND CMAKE_MODULE_PATH "${SKIA_lib_DIR}/cmake/modules")


#-----------------------------------------------------------------------
# LibCMaker_<LibName> specific vars and options
#-----------------------------------------------------------------------


#-----------------------------------------------------------------------
# Library specific vars and options
#-----------------------------------------------------------------------

macro(skia_not _option _out_value)
  if(${_option})
    set(${_out_value} "false")
  else()
    set(${_out_value} "true")
  endif()
endmacro()

macro(skia_option _option _value)
  if(${_value})
    set(_opt_value "true")
  else()
    set(_opt_value "false")
  endif()
  set(${_option} "${_opt_value}" CACHE STRING "${_option}")
  list(APPEND all_skia_options ${_option})
  unset(_opt_value)
endmacro()


# LibCMaker options

skia_option(export_icu_from_skia true)  # default: true


# Skia options

# TODO:
#skia_not(is_win is_not_win)

skia_option(skia_enable_api_available_macro true)  # default: true

skia_option(skia_use_system_expat false)  # default: is_official_build
skia_option(skia_use_system_freetype2 false)  # default: (is_official_build || !(is_android || sanitize == "MSAN")) && !is_fuchsia
skia_option(skia_use_system_harfbuzz false)  # default: is_official_build
skia_option(skia_use_system_icu false)  # default: is_official_build
skia_option(skia_use_system_libjpeg_turbo false)  # default: is_official_build
skia_option(skia_use_system_libpng false)  # default: is_official_build
skia_option(skia_use_system_libwebp false)  # default: is_official_build
skia_option(skia_use_system_zlib false)  # default: is_official_build

skia_option(skia_use_expat true)  # default: true
skia_option(skia_use_freetype true)  # default: is_android || is_fuchsia || is_linux
skia_option(skia_use_freetype_woff2 false)  # default: false
skia_option(skia_use_harfbuzz true)  # default: true
skia_option(skia_use_icu true)  # default: !is_fuchsia

skia_option(skia_use_libjpeg_turbo_decode true)  # default: true
skia_option(skia_use_libjpeg_turbo_encode true)  # default: true
skia_option(skia_use_libpng_decode true)  # default: true
skia_option(skia_use_libpng_encode true)  # default: true
skia_option(skia_use_libwebp_decode true)  # default: true
skia_option(skia_use_libwebp_encode true)  # default: true
# TODO:
#skia_option(skia_use_piex ${is_not_win})  # default: !is_win
skia_option(skia_use_zlib true)  # default: true


skia_option(skia_enable_gpu true)  # default: true
skia_option(skia_enable_discrete_gpu ${skia_enable_gpu})  # default: true
skia_option(skia_use_angle false)  # default: false
skia_option(skia_use_direct3d false)  # default: false
skia_option(skia_use_egl false)  # default: false
skia_option(skia_use_gl ${skia_enable_gpu})  # default: !is_fuchsia
skia_option(skia_use_metal false)  # default: false
# TODO:
#skia_option(skia_use_x11 ${is_linux})  # default: is_linux

skia_option(skia_enable_sksl ${skia_enable_gpu})  # default: true
skia_option(skia_enable_skgpu_v1 ${skia_enable_gpu})  # default: true


skia_option(skia_enable_graphite false)  # default: false
skia_option(skia_use_ffmpeg false)  # default: false
skia_option(skia_use_sfml false)  # default: false
skia_option(skia_use_wuffs false)  # default: false
skia_option(skia_use_xps false)  # default: true
skia_not(skia_use_wuffs skia_not_use_wuffs)
skia_option(skia_use_libgifcodec ${skia_not_use_wuffs})  # default: !skia_use_wuffs
# TODO: AND is_not_win
#skia_option(skia_use_dng_sdk true)  # default: !is_fuchsia && skia_use_libjpeg_turbo_decode && skia_use_zlib


skia_option(skia_enable_particles true)  # default: true
skia_option(skia_enable_skshaper true)  # default: true
# TODO: is_win AND is_component_build AND MSVC
#skia_option(skia_enable_skottie true)  # default: !(is_win && is_component_build)
# TODO: is_win AND is_component_build AND MSVC
#skia_option(skia_enable_svg true)  # default: !is_component_build

skia_option(skia_enable_skparagraph true)  # default: true
skia_option(paragraph_gms_enabled true)  # default: true

skia_option(skia_enable_sktext true)  # default: true
skia_option(text_gms_enabled true)  # default: true

skia_option(skia_enable_pdf true)  # default: true
skia_option(skia_pdf_subset_harfbuzz ${skia_use_harfbuzz})  # default: skia_use_harfbuzz

skia_option(skia_use_fixed_gamma_text false)  # default: is_android


#-----------------------------------------------------------------------
# Build, install and find the library
#-----------------------------------------------------------------------

cmr_find_package(
  LibCMaker_DIR   ${LibCMaker_DIR}
  NAME            ${SKIA_lib_NAME}
  VERSION         ${SKIA_lib_VERSION}
  COMPONENTS      ${SKIA_lib_COMPONENTS}
  LIB_DIR         ${SKIA_lib_DIR}
  REQUIRED
  CONFIG
)
