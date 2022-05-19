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

# Part of "LibCMaker/cmake/cmr_build_rules.cmake".

  # NOTE: Use pattern '*.gn*' for search of usage of options in Skia source tree.

  # TODO: add these modules:
  # androidkit
  # audioplayer
  # canvaskit
  # pathkit


  # NOTE: See 'declare_args()' in 'skia/gn/BUILDCONFIG.gn'
  # and in 'skia/gn/skia/BUILD.gn' for useful args.

  cmake_policy(PUSH)

  cmake_minimum_required(VERSION 3.23)

  include(GNUInstallDirs)
  include(CheckLanguage)

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

  macro(skia_options_to_gn_args _skia_gn_args)
    foreach(_option IN LISTS all_skia_options)
      string(APPEND ${_skia_gn_args} " ${_option}=${${_option}}")
    endforeach()
  endmacro()


  #-----------------------------------------------------------------------
  # OS specifics
  #
  if(WIN32)
    set(target_os "win")
  elseif(IOS)
    set(target_os "ios")
  elseif(APPLE)
    set(target_os "mac")
  elseif(ANDROID)
    set(target_os "android")
  elseif("${CMAKE_SYSTEM_NAME}" MATCHES "Linux")
    set(target_os "linux")
  else()
    cmr_print_error("Unsupported platform.")
  endif()

  set(_is_win false)
  set(_is_ios false)
  set(_is_mac false)
  set(_is_android false)
  set(_is_linux false)
  set(_is_${target_os} true)

  set(is_win ${_is_win} CACHE STRING "is_win")
  set(is_ios ${_is_ios} CACHE STRING "is_ios")
  set(is_mac ${_is_mac} CACHE STRING "is_mac")
  set(is_android ${_is_android} CACHE STRING "is_android")
  set(is_linux ${_is_linux} CACHE STRING "is_linux")

  string(APPEND skia_GN_ARGS " target_os=\"${target_os}\"")

  set(_skia_use_ndk_images false)

  if(is_android)
    if(ANDROID_NDK_MAJOR LESS 22)
      cmr_print_error("Android NDK r22+ is required.")
    endif()

    set(ndk ${CMAKE_ANDROID_NDK})
    set(ndk_api ${CMAKE_SYSTEM_VERSION})

    if(CMAKE_ANDROID_ARCH_ABI STREQUAL "armeabi-v7a")
      set(target_cpu "arm")
    elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "arm64-v8a")
      set(target_cpu "arm64")
    elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "x86")
      set(target_cpu "x86")
    elseif(CMAKE_ANDROID_ARCH_ABI STREQUAL "x86_64")
      set(target_cpu "x64")
    else()
      cmr_print_error("Unsupported CPU arch.")
    endif()

    if(is_android AND DEFINED ndk_api AND ndk_api VERSION_GREATER_EQUAL 30)
      set(_skia_use_ndk_images true)
    endif()

    string(APPEND skia_GN_ARGS " ndk=\"${ndk}\"")
    string(APPEND skia_GN_ARGS " ndk_api=${ndk_api}")
    string(APPEND skia_GN_ARGS " target_cpu=\"${target_cpu}\"")
  endif()

  # NOTE: From 'declare_args()' in 'skia/gn/BUILDCONFIG.gn'.
  #  ios_min_target = ""


  #-----------------------------------------------------------------------
  # Find required tools
  #
  check_language(C)
  if(CMAKE_C_COMPILER)
    enable_language(C)
  else()
    cmr_print_error("No C support.")
  endif()

  check_language(CXX)
  if(CMAKE_CXX_COMPILER)
    enable_language(CXX)
  else()
    cmr_print_error("No CXX support.")
  endif()

  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU"
      AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS 9.0.0)
    cmr_print_error("GNU g++ compiler version 9+ is required.")
  endif()

  if((CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang"
       OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
       AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS 9.0.0)
    cmr_print_error("Clang compiler version 9+ is required.")
  endif()

  if(MSVC AND CMAKE_CXX_COMPILER_VERSION VERSION_LESS 19.15)
    cmr_print_error("MSVC compiler version 19.15+ is required.")
  endif()

  if(is_linux OR is_mac OR MINGW)  # TODO: if CMake gen = "Unix Makefiles"
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU"
        OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang"
        OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")

      #  ar = "ar"
      #  cc = "cc"
      #  cxx = "c++"
      if(CMAKE_C_COMPILER)
        string(APPEND skia_GN_ARGS " cc=\"${CMAKE_C_COMPILER}\"")
      endif()
      if(CMAKE_CXX_COMPILER)
        string(APPEND skia_GN_ARGS " cxx=\"${CMAKE_CXX_COMPILER}\"")
      endif()
      if(CMAKE_AR)
        string(APPEND skia_GN_ARGS " ar=\"${CMAKE_AR}\"")
      endif()

      #  cc_wrapper = ""
      if(CMAKE_CXX_COMPILER_LAUNCHER)
        string(APPEND skia_GN_ARGS
          " cc_wrapper=\"${CMAKE_CXX_COMPILER_LAUNCHER}\""
        )
      endif()
    endif()
  endif()

  if(is_win AND MSVC)
    #  win_sdk = "C:/Program Files (x86)/Windows Kits/10"
    #  win_sdk_version = ""
    #  win_vc = ""
    #  win_toolchain_version = ""
    #  clang_win = ""
    #  clang_win_version = ""

    if(cmr_VS_TOOLSET_DIR)
      string(APPEND skia_GN_ARGS " win_vc=\"${cmr_VS_TOOLSET_DIR}\"")
    endif()
    if(cmr_VS_TOOLSET_VERSION)
      string(APPEND skia_GN_ARGS " win_toolchain_version=\"${cmr_VS_TOOLSET_VERSION}\"")
    endif()
    if(cmr_WINDOWS_KITS_DIR)
      string(APPEND skia_GN_ARGS " win_sdk=\"${cmr_WINDOWS_KITS_DIR}\"")
    endif()
    if(cmr_WINDOWS_KITS_VERSION)
      string(APPEND skia_GN_ARGS " win_sdk_version=\"${cmr_WINDOWS_KITS_VERSION}\"")
    endif()

    if(CMAKE_GENERATOR_PLATFORM STREQUAL "ARM")
      set(target_cpu "arm")
    elseif(CMAKE_GENERATOR_PLATFORM STREQUAL "ARM64")
      set(target_cpu "arm64")
    elseif(CMAKE_GENERATOR_PLATFORM STREQUAL "Win32")
      set(target_cpu "x86")
    elseif(CMAKE_GENERATOR_PLATFORM STREQUAL "x64")
      set(target_cpu "x64")
    else()
      cmr_print_error("Unsupported CPU arch.")
    endif()

    string(APPEND skia_GN_ARGS " target_cpu=\"${target_cpu}\"")

    # TODO: clang_win
    #  clang_win = ""
    #  clang_win_version = ""
    # NOTE: https://skia.org/docs/user/build/#highly-recommended-build-with-clang-cl
  endif()

  if(XCODE)
    if(is_mac AND CMAKE_OSX_SYSROOT)
      string(APPEND skia_GN_ARGS " xcode_sysroot=\"${CMAKE_OSX_SYSROOT}\"")
    endif()
    if(is_ios AND CMAKE_OSX_SYSROOT_INT)
      string(APPEND skia_GN_ARGS " xcode_sysroot=\"${CMAKE_OSX_SYSROOT_INT}\"")
    endif()
  endif()

  if(is_ios)
    if(ARCHS STREQUAL "armv7")
      set(target_cpu "arm")
    elseif(ARCHS STREQUAL "arm64")
      set(target_cpu "arm64")
    elseif(ARCHS STREQUAL "i386")
      set(target_cpu "x86")
    elseif(ARCHS STREQUAL "x86_64")
      set(target_cpu "x64")
    else()
      cmr_print_error("Unsupported CPU arch.")
    endif()

    string(APPEND skia_GN_ARGS " target_cpu=\"${target_cpu}\"")

    # ios_min_target = ""
    if(DEPLOYMENT_TARGET)
      string(APPEND skia_GN_ARGS " ios_min_target=\"${DEPLOYMENT_TARGET}\"")
    endif()
  endif()

  find_package(Git 2.17.1 REQUIRED)
  find_package(Python REQUIRED COMPONENTS Interpreter)

  if(Python_VERSION VERSION_LESS 2.7
      OR Python_VERSION VERSION_GREATER 3.0 AND Python_VERSION VERSION_LESS 3.8)
    cmr_print_error("depot_tools requires python 2.7 or 3.8.")
  endif()

  find_program(Ninja_EXECUTABLE "ninja" REQUIRED)


  #-----------------------------------------------------------------------
  # Variables
  #
  set(skia_DEPOT_TOOLS_DIR "${lib_UNPACK_TO_DIR}/depot_tools")
  set(skia_SRC_DIR "${lib_SRC_DIR}")
  set(skia_BUILD_DIR "${lib_BUILD_DIR}/build_ninja")
  set(skia_CMAKE_GEN_DIR "${lib_BUILD_DIR}/build_ninja_cmake")


  if(NOT "$ENV{PATH}" STRLESS "")
    if(CMAKE_HOST_WIN32 AND CMAKE_HOST_SYSTEM_NAME MATCHES "Windows"
        AND NOT CYGWIN)
      set(_PATH_SEP "$<SEMICOLON>")
    else()
      set(_PATH_SEP ":")
    endif()
    set(_PATH_ENV "$ENV{PATH}")
    list(JOIN _PATH_ENV "${_PATH_SEP}" _PATH)
    # Get the system search path as a list.
    #file(TO_CMAKE_PATH "$ENV{PATH}" _PATH)
  endif()
  set(skia_ENV
    "DEPOT_TOOLS_UPDATE=0"
    "PATH=$<SHELL_PATH:${skia_DEPOT_TOOLS_DIR}>${_PATH_SEP}${_PATH}"
  )


  #-----------------------------------------------------------------------
  # Flags
  #

  # NOTE: From 'declare_args()' in 'skia/gn/skia/BUILD.gn'.
  #  malloc = ""
  #  werror = false
  #  xcode_sysroot = ""

  # List of flags:
  #extra_cflags = [
  #    "--flag1",
  #    "--flag2",
  #    "--flag3",
  #]

  if(WIN32 AND MSVC)
    set(flag_MT_MD_sfx "$<$<CONFIG:Debug>:d>")
    if(BUILD_SHARED_LIBS)
      set(flag_MT_MD "/MD${flag_MT_MD_sfx}")
    else()
      set(flag_MT_MD "/MT${flag_MT_MD_sfx}")
    endif()
    string(APPEND extra_cflags " \"${flag_MT_MD}\",")

    if(TARGETING_XP_64 OR TARGETING_XP)
      string(APPEND extra_cflags " \"/D_ATL_XP_TARGETING\",")
    endif()
  endif()

  if(extra_cflags)
    set(extra_cflags "[${extra_cflags}]")
  endif()


  # TODO: Make flags in form of GN-list:  set(extra_cflags_c "[\"flag1\", \"flag2\", ...]")
  if(CMAKE_ASM_FLAGS OR CMAKE_ASM_FLAGS_DEBUG OR CMAKE_ASM_FLAGS_RELEASE)
    #set(extra_asmflags "${CMAKE_ASM_FLAGS} $<IF:$<CONFIG:Debug>,${CMAKE_ASM_FLAGS_DEBUG},${CMAKE_ASM_FLAGS_RELEASE}>")
  endif()
  if(CMAKE_C_FLAGS OR CMAKE_C_FLAGS_DEBUG OR CMAKE_C_FLAGS_RELEASE)
    #set(extra_cflags_c "${CMAKE_C_FLAGS} $<IF:$<CONFIG:Debug>,${CMAKE_C_FLAGS_DEBUG},${CMAKE_C_FLAGS_RELEASE}>")
  endif()
  if(CMAKE_CXX_FLAGS OR CMAKE_CXX_FLAGS_DEBUG OR CMAKE_CXX_FLAGS_RELEASE)
    #set(extra_cflags_cc "${CMAKE_CXX_FLAGS} $<IF:$<CONFIG:Debug>,${CMAKE_CXX_FLAGS_DEBUG},${CMAKE_CXX_FLAGS_RELEASE}>")
  endif()
  if(BUILD_SHARED_LIBS AND CMAKE_SHARED_LINKER_FLAGS)
    #set(extra_ldflags "${CMAKE_SHARED_LINKER_FLAGS}")
  endif()


  if(extra_cflags)
    string(APPEND skia_GN_ARGS " extra_cflags=${extra_cflags}")
  endif()
  if(extra_cflags_c)
    string(APPEND skia_GN_ARGS " extra_cflags_c=${extra_cflags_c}")
  endif()
  if(extra_cflags_cc)
    string(APPEND skia_GN_ARGS " extra_cflags_cc=${extra_cflags_cc}")
  endif()
  if(extra_asmflags)
    string(APPEND skia_GN_ARGS " extra_asmflags=${extra_asmflags}")
  endif()
  if(extra_ldflags)
    string(APPEND skia_GN_ARGS " extra_ldflags=${extra_ldflags}")
  endif()


  #-----------------------------------------------------------------------
  # GN options
  #
  skia_not(is_win is_not_win)

  set(is_official_build "$<IF:$<CONFIG:Debug>,false,true>")  # default: false
  string(APPEND skia_GN_ARGS " is_official_build=${is_official_build}")

  set(is_debug "$<IF:$<CONFIG:Debug>,true,false>")  # default: !is_official_build
  string(APPEND skia_GN_ARGS " is_debug=${is_debug}")

  skia_option(is_component_build ${BUILD_SHARED_LIBS})  # default: false

  skia_option(skia_enable_api_available_macro true)  # default: true

  skia_option(skia_use_ndk_images ${_skia_use_ndk_images})

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
  skia_option(skia_use_runtime_icu false)  # default: false
  skia_option(skia_use_sfntly ${skia_use_icu})  # default: skia_use_icu

  skia_option(skia_use_libjpeg_turbo_decode true)  # default: true
  skia_option(skia_use_libjpeg_turbo_encode true)  # default: true
  skia_option(skia_use_libpng_decode true)  # default: true
  skia_option(skia_use_libpng_encode true)  # default: true
  skia_option(skia_use_libwebp_decode true)  # default: true
  skia_option(skia_use_libwebp_encode true)  # default: true
  skia_option(skia_use_piex ${is_not_win})  # default: !is_win
  skia_option(skia_use_zlib true)  # default: true


  skia_option(skia_enable_gpu true)  # default: true
  skia_option(skia_enable_discrete_gpu ${skia_enable_gpu})  # default: true
  skia_option(skia_use_angle false)  # default: false
  skia_option(skia_use_dawn false)  # default: false
  skia_option(skia_use_direct3d false)  # default: false
  skia_option(skia_use_egl false)  # default: false
  skia_option(skia_use_gl ${skia_enable_gpu})  # default: !is_fuchsia
  skia_option(skia_use_metal false)  # default: false
  skia_option(skia_use_x11 ${is_linux})  # default: is_linux

  if(is_android AND DEFINED ndk_api AND ndk_api VERSION_GREATER_EQUAL 24)
    skia_option(skia_use_vulkan ${skia_enable_gpu})  # default in tis case: true
  else()
    skia_option(skia_use_vulkan false)  # default in tis case: is_fuchsia
  endif()

  skia_option(skia_enable_sksl ${skia_enable_gpu})  # default: true
  skia_option(skia_enable_skgpu_v1 ${skia_enable_gpu})  # default: true


  skia_option(skia_enable_graphite false)  # default: false
  skia_option(skia_use_ffmpeg false)  # default: false
  skia_option(skia_use_sfml false)  # default: false
  skia_option(skia_use_wuffs false)  # default: false
  skia_option(skia_use_xps false)  # default: true
  skia_not(skia_use_wuffs skia_not_use_wuffs)
  skia_option(skia_use_libgifcodec ${skia_not_use_wuffs})  # default: !skia_use_wuffs


  # NOTE: These options war enabled in Debug config, but we disable it.
  # is_skia_standalone = true
  # is_skia_dev_build = is_skia_standalone && !is_official_build
  skia_option(skia_enable_tools false)  # default: is_skia_dev_build
  skia_option(skia_enable_android_utils false)  # default: is_skia_dev_build
  skia_option(skia_enable_direct3d_debug_layer false)  # default: skia_enable_gpu_debug_layers
  skia_option(skia_enable_gpu_debug_layers false)  # default: is_skia_dev_build && is_debug
  skia_option(skia_enable_metal_debug_info false)  # default: skia_enable_gpu_debug_layers
  skia_option(skia_enable_skvm_jit_when_possible false)  # default: is_skia_dev_build
  skia_option(skia_enable_spirv_validation false)  # default: is_skia_dev_build && is_debug && !skia_use_dawn
  skia_option(skia_enable_vulkan_debug_layers false)  # default: skia_enable_gpu_debug_layers
  skia_option(skia_use_libheif false)  # default: is_skia_dev_build
  skia_option(skia_use_lua false)  # default: is_skia_dev_build && !is_ios


  skia_option(skia_use_fontconfig ${is_linux})  # default: is_linux

  if(is_android AND skia_use_expat AND skia_use_freetype)
    set(_skia_enable_fontmgr_android true)
  else()
    set(_skia_enable_fontmgr_android false)
  endif()
  skia_option(skia_enable_fontmgr_android ${_skia_enable_fontmgr_android})  # default: skia_use_expat && skia_use_freetype

  skia_option(skia_enable_fontmgr_custom_directory ${skia_use_freetype})  # default: skia_use_freetype && !is_fuchsia
  skia_option(skia_enable_fontmgr_custom_embedded false)  # default: skia_use_freetype && !is_fuchsia
  skia_option(skia_enable_fontmgr_custom_empty false)  # default: skia_use_freetype

  if(skia_use_freetype AND skia_use_fontconfig)
    set(_skia_enable_fontmgr_fontconfig true)
    set(_skia_enable_fontmgr_FontConfigInterface true)
  else()
    set(_skia_enable_fontmgr_fontconfig false)
    set(_skia_enable_fontmgr_FontConfigInterface false)
  endif()
  skia_option(skia_enable_fontmgr_fontconfig ${_skia_enable_fontmgr_fontconfig})  # default: skia_use_freetype && skia_use_fontconfig
  skia_option(skia_enable_fontmgr_FontConfigInterface
    # default: skia_use_freetype && skia_use_fontconfig
    ${_skia_enable_fontmgr_FontConfigInterface}
  )

  skia_option(skia_use_fonthost_mac false)  # default: is_mac || is_ios
  skia_option(skia_enable_fontmgr_win false)  # default: is_win
  skia_option(skia_enable_fontmgr_win_gdi false)  # default: is_win && !skia_enable_winuwp

  if(skia_use_libjpeg_turbo_decode AND skia_use_zlib AND is_not_win)
    set(_skia_use_dng_sdk true)
  else()
    set(_skia_use_dng_sdk false)
  endif()
  skia_option(skia_use_dng_sdk ${_skia_use_dng_sdk})  # default: !is_fuchsia && skia_use_libjpeg_turbo_decode && skia_use_zlib


  skia_option(skia_enable_particles true)  # default: true
  skia_option(skia_enable_skshaper true)  # default: true

  if(is_component_build AND (is_win AND MSVC OR is_mac OR is_ios))
    set(_skia_enable_skottie false)
  else()
    set(_skia_enable_skottie true)
  endif()
  skia_option(skia_enable_skottie ${_skia_enable_skottie})  # default: !(is_win && is_component_build)

  if(is_component_build AND (is_win AND MSVC OR is_mac OR is_ios))
    set(_skia_enable_svg false)
  else()
    set(_skia_enable_svg true)
  endif()
  skia_option(skia_enable_svg ${_skia_enable_svg})  # default: !is_component_build

  skia_option(skia_enable_skparagraph true)  # default: true
  skia_option(paragraph_gms_enabled true)  # default: true
  skia_option(paragraph_tests_enabled false)  # default: true
  skia_option(paragraph_bench_enabled false)  # default: false

  skia_option(skia_enable_sktext true)  # default: true
  skia_option(text_gms_enabled true)  # default: true
  skia_option(text_tests_enabled false)  # default: true
  skia_option(text_bench_enabled false)  # default: false

  skia_option(skia_enable_pdf true)  # default: true
  skia_option(skia_pdf_subset_harfbuzz ${skia_use_harfbuzz})  # default: skia_use_harfbuzz

  # NOTE: not needed for skia lib, only for tests
  skia_option(skia_enable_skrive false)  # default: true

  skia_option(skia_use_fixed_gamma_text false)  # default: is_android


  # Stubs for SkiaConfig.in.cmake
  skia_option(skia_enable_winuwp false)  # default: false
  set(is_fuchsia false CACHE STRING "is_fuchsia")


  #-----------------------------------------------------------------------
  # Configure and build
  #
  skia_options_to_gn_args(skia_GN_ARGS)
  message(STATUS "skia_GN_ARGS: ${skia_GN_ARGS}")

  set(configure_STAMP "${lib_BUILD_DIR}/skia_configure.stamp")
  add_custom_command(OUTPUT ${configure_STAMP}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${skia_BUILD_DIR}
    COMMAND ${CMAKE_COMMAND} -E env ${skia_ENV}
      bin/gn gen ${skia_BUILD_DIR} "--args=${skia_GN_ARGS}"
    COMMAND ${CMAKE_COMMAND} -E touch ${configure_STAMP}
    WORKING_DIRECTORY ${skia_SRC_DIR}
    VERBATIM
    COMMENT "Configure Skia"
  )

  # NOTE: For debug.
  #set(configure_cmake_STAMP "${lib_BUILD_DIR}/skia_configure_cmake.stamp")
  #add_custom_command(OUTPUT ${configure_cmake_STAMP}
  #  COMMAND ${CMAKE_COMMAND} -E make_directory ${skia_CMAKE_GEN_DIR}
  #  COMMAND ${CMAKE_COMMAND} -E env ${skia_ENV}
  #    bin/gn gen ${skia_CMAKE_GEN_DIR}
  #      "--args=${skia_GN_ARGS}"
  #      "--ide=json"
  #      "--json-ide-script=${skia_SRC_DIR}/gn/gn_to_cmake.py"
  #  COMMAND ${CMAKE_COMMAND} -E touch ${configure_STAMP}
  #  WORKING_DIRECTORY ${skia_SRC_DIR}
  #  VERBATIM
  #  COMMENT "Configure Skia CMake"
  #)

  if(NOT cmr_BUILD_MULTIPROC
        OR cmr_BUILD_MULTIPROC AND NOT cmr_BUILD_MULTIPROC_CNT)
    set(cmr_BUILD_MULTIPROC_CNT "1")
  endif()

  if(CMAKE_VERBOSE_MAKEFILE)
    set(verbose_ninja "-v")
  endif()

  set(build_STAMP "${lib_BUILD_DIR}/skia_build.stamp")
  add_custom_command(OUTPUT ${build_STAMP}
    COMMAND ${CMAKE_COMMAND} -E env ${skia_ENV}
      ${Ninja_EXECUTABLE}
        "-j" "${cmr_BUILD_MULTIPROC_CNT}"
        "-C" ${skia_BUILD_DIR}
        ${verbose_ninja}
    COMMAND ${CMAKE_COMMAND} -E touch ${build_STAMP}
    WORKING_DIRECTORY ${skia_SRC_DIR}
    VERBATIM
    COMMENT "Build Skia"
    DEPENDS ${configure_STAMP} ${configure_cmake_STAMP}
  )

  add_custom_target(build_skia ALL
    DEPENDS ${build_STAMP}
  )


  #-----------------------------------------------------------------------
  # Install
  #


  #  PUBLIC_HEADER DESTINATION include/litehtml
  #  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  #  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  #  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  #  FRAMEWORK DESTINATION ${CMAKE_INSTALL_LIBDIR}


  if(BUILD_SHARED_LIBS)
    set(lib_PFX ${CMAKE_SHARED_LIBRARY_PREFIX})
    set(lib_SFX ${CMAKE_SHARED_LIBRARY_SUFFIX})
    if(is_mac OR is_ios)
      set(lib_SFX ".so")
    endif()
  else()
    set(lib_PFX ${CMAKE_STATIC_LIBRARY_PREFIX})
    set(lib_SFX ${CMAKE_STATIC_LIBRARY_SUFFIX})
  endif()

  set(skia_INSTALL_INCLUDE_DIR "${CMAKE_INSTALL_INCLUDEDIR}/skia")
  set(skia_INSTALL_EXPERIMENTAL_DIR "${skia_INSTALL_INCLUDE_DIR}/experimental")
  set(skia_INSTALL_MODULES_DIR "${skia_INSTALL_INCLUDE_DIR}/modules")
  set(skia_INSTALL_BIN_DIR "${CMAKE_INSTALL_BINDIR}")
  set(skia_INSTALL_LIB_DIR "${CMAKE_INSTALL_LIBDIR}")
  set(skia_INSTALL_PDB_DIR "${CMAKE_INSTALL_BINDIR}")

  set(skia_INSTALL_DLL_DIR
    "$<IF:$<AND:$<BOOL:${is_win}>,$<BOOL:${BUILD_SHARED_LIBS}>>,${skia_INSTALL_BIN_DIR},${skia_INSTALL_LIB_DIR}>"
  )

  set(brotli_FILE_NAME "${lib_PFX}brotli${lib_SFX}")
  set(dng_sdk_FILE_NAME "${lib_PFX}dng_sdk${lib_SFX}")
  set(expat_FILE_NAME "${lib_PFX}expat${lib_SFX}")
  set(freetype2_FILE_NAME "${lib_PFX}freetype2${lib_SFX}")
  set(harfbuzz_FILE_NAME "${lib_PFX}harfbuzz${lib_SFX}")
  set(icu_FILE_NAME "${lib_PFX}icu${lib_SFX}")
  # icudtl.dat
  # TODO: icudata_FILE_NAME
  # TODO: generator expr (if android, android_small, cast, common, ios in <skia/third_party/externals/icu>) for icudtb.dat and icudtl_extra.dat
  set(icudata_FILE_NAME "icudtl.dat")
  set(libjpeg_FILE_NAME "libjpeg${lib_SFX}")
  set(libpng_FILE_NAME "libpng${lib_SFX}")
  set(libwebp_FILE_NAME "libwebp${lib_SFX}")
  set(libwebp_sse41_FILE_NAME "libwebp_sse41${lib_SFX}")
  set(piex_FILE_NAME "${lib_PFX}piex${lib_SFX}")
  set(sfntly_FILE_NAME "${lib_PFX}sfntly${lib_SFX}")
  set(spirv_cross_FILE_NAME "${lib_PFX}spirv_cross${lib_SFX}")
  set(zlib_FILE_NAME "${lib_PFX}zlib${lib_SFX}")
  set(compression_utils_portable_FILE_NAME
    "${lib_PFX}compression_utils_portable${lib_SFX}"
  )
  set(pathkit_FILE_NAME "${lib_PFX}pathkit${lib_SFX}")
  set(video_decoder_FILE_NAME "${lib_PFX}video_decoder${lib_SFX}")
  set(video_encoder_FILE_NAME "${lib_PFX}video_encoder${lib_SFX}")

  set(particles_FILE_NAME "${lib_PFX}particles${lib_SFX}")
  set(skottie_FILE_NAME "${lib_PFX}skottie${lib_SFX}")
  set(skresources_FILE_NAME "${lib_PFX}skresources${lib_SFX}")
  set(sksg_FILE_NAME "${lib_PFX}sksg${lib_SFX}")
  set(svg_FILE_NAME "${lib_PFX}svg${lib_SFX}")

  set(skia_FILE_NAME "${lib_PFX}skia${lib_SFX}")
  set(skia_DLL_LIB_FILE_NAME "skia.dll.lib")
  set(skia_DLL_PDB_FILE_NAME "skia.dll.pdb")

  set(skparagraph_FILE_NAME "${lib_PFX}skparagraph${lib_SFX}")
  set(skparagraph_DLL_LIB_FILE_NAME "skparagraph.dll.lib")
  set(skparagraph_DLL_PDB_FILE_NAME "skparagraph.dll.pdb")

  set(skshaper_FILE_NAME "${lib_PFX}skshaper${lib_SFX}")
  set(skshaper_DLL_LIB_FILE_NAME "skshaper.dll.lib")
  set(skshaper_DLL_PDB_FILE_NAME "skshaper.dll.pdb")

  set(sktext_FILE_NAME "${lib_PFX}sktext${lib_SFX}")
  set(sktext_DLL_LIB_FILE_NAME "sktext.dll.lib")
  set(sktext_DLL_PDB_FILE_NAME "sktext.dll.pdb")

  set(skunicode_FILE_NAME "${lib_PFX}skunicode${lib_SFX}")
  set(skunicode_DLL_LIB_FILE_NAME "skunicode.dll.lib")
  set(skunicode_DLL_PDB_FILE_NAME "skunicode.dll.pdb")


  # -------------------------------------
  # third_party/brotli/BUILD.gn
  # -------------------------------------
  # The only consumer of brotli is freetype and it only needs to decode brotli.
  if(NOT is_component_build AND skia_use_freetype_woff2)
    install(
      FILES "${skia_BUILD_DIR}/${brotli_FILE_NAME}"
      DESTINATION "${skia_INSTALL_LIB_DIR}"
    )
  endif()


  # -------------------------------------
  # third_party/cpu-features/BUILD.gn
  # -------------------------------------


  # -------------------------------------
  # third_party/dng_sdk/BUILD.gn
  # -------------------------------------
  if(NOT is_component_build AND skia_use_dng_sdk)
    install(
      FILES "${skia_BUILD_DIR}/${dng_sdk_FILE_NAME}"
      DESTINATION "${skia_INSTALL_LIB_DIR}"
    )
  endif()


  # -------------------------------------
  # third_party/expat/BUILD.gn
  # -------------------------------------
  if(NOT is_component_build AND skia_use_expat AND NOT skia_use_system_expat)
    install(
      FILES "${skia_BUILD_DIR}/${expat_FILE_NAME}"
      DESTINATION "${skia_INSTALL_LIB_DIR}"
    )
  endif()


  # -------------------------------------
  # third_party/freetype2/BUILD.gn
  # -------------------------------------
  if(NOT is_component_build
      AND skia_use_freetype AND NOT skia_use_system_freetype2)
    install(
      FILES "${skia_BUILD_DIR}/${freetype2_FILE_NAME}"
      DESTINATION "${skia_INSTALL_LIB_DIR}"
    )
  endif()


  # -------------------------------------
  # third_party/harfbuzz/BUILD.gn
  # -------------------------------------
  if(NOT is_component_build
      AND skia_use_harfbuzz AND NOT skia_use_system_harfbuzz)
    install(
      FILES "${skia_BUILD_DIR}/${harfbuzz_FILE_NAME}"
      DESTINATION "${skia_INSTALL_LIB_DIR}"
    )
  endif()


  # -------------------------------------
  # third_party/icu/BUILD.gn
  # -------------------------------------
  if(skia_use_icu AND NOT skia_use_system_icu)
    install(
      FILES
        "${skia_BUILD_DIR}/${icudata_FILE_NAME}"
      DESTINATION "${skia_INSTALL_DLL_DIR}"
    )
    if(NOT is_component_build)
      install(
        FILES
          "${skia_BUILD_DIR}/${icu_FILE_NAME}"
        DESTINATION "${skia_INSTALL_LIB_DIR}"
      )
    endif()
  endif()


  # -------------------------------------
  # third_party/libjpeg-turbo/BUILD.gn
  # -------------------------------------
  # TODO:
  #if(skia_use_libjpeg_turbo_decode OR skia_use_libjpeg_turbo_encode AND
  #    NOT skia_use_system_libjpeg_turbo AND NOT is_component_build)
  if(NOT is_component_build AND NOT skia_use_system_libjpeg_turbo)
    install(
      FILES "${skia_BUILD_DIR}/${libjpeg_FILE_NAME}"
      DESTINATION "${skia_INSTALL_LIB_DIR}"
    )
  endif()


  # -------------------------------------
  # third_party/libpng/BUILD.gn
  # -------------------------------------
  # TODO:
  #if(skia_use_libpng_decode OR skia_use_libpng_encode AND
  #    NOT skia_use_system_libpng AND NOT is_component_build)
  if(NOT is_component_build AND NOT skia_use_system_libpng)
    install(
      FILES "${skia_BUILD_DIR}/${libpng_FILE_NAME}"
      DESTINATION "${skia_INSTALL_LIB_DIR}"
    )
  endif()


  # -------------------------------------
  # third_party/libwebp/BUILD.gn
  # -------------------------------------
  # TODO:
  #if(skia_use_libwebp_decode OR skia_use_libwebp_encode AND
  #    NOT skia_use_system_libwebp AND NOT is_component_build)
  if(NOT is_component_build AND NOT skia_use_system_libwebp)
    install(
      FILES
        "${skia_BUILD_DIR}/${libwebp_FILE_NAME}"
        "${skia_BUILD_DIR}/${libwebp_sse41_FILE_NAME}"
      DESTINATION "${skia_INSTALL_LIB_DIR}"
    )
  endif()


  # -------------------------------------
  # third_party/piex/BUILD.gn
  # -------------------------------------
  if(NOT is_component_build AND skia_use_piex)
    install(
      FILES "${skia_BUILD_DIR}/${piex_FILE_NAME}"
      DESTINATION "${skia_INSTALL_LIB_DIR}"
    )
  endif()


  # -------------------------------------
  # third_party/sfntly/BUILD.gn
  # -------------------------------------
  if(NOT is_component_build
      AND skia_use_zlib AND skia_enable_pdf AND skia_use_icu
      AND NOT skia_use_harfbuzz AND skia_use_sfntly)
    install(
      FILES "${skia_BUILD_DIR}/${sfntly_FILE_NAME}"
      DESTINATION "${skia_INSTALL_LIB_DIR}"
    )
  endif()


  # -------------------------------------
  # third_party/spirv-cross/BUILD.gn
  # -------------------------------------
  if(NOT is_component_build AND skia_enable_gpu AND skia_use_direct3d)
    install(
      FILES "${skia_BUILD_DIR}/${spirv_cross_FILE_NAME}"
      DESTINATION "${skia_INSTALL_LIB_DIR}"
    )
  endif()


  # -------------------------------------
  # third_party/zlib/BUILD.gn
  # -------------------------------------
  if(NOT is_component_build AND skia_use_zlib)
    if(NOT skia_use_system_zlib)
      install(
        FILES "${skia_BUILD_DIR}/${zlib_FILE_NAME}"
        DESTINATION "${skia_INSTALL_LIB_DIR}"
      )
    endif()

    install(
      FILES "${skia_BUILD_DIR}/${compression_utils_portable_FILE_NAME}"
      DESTINATION "${skia_INSTALL_LIB_DIR}"
    )
  endif()


  # -------------------------------------
  # BUILD.gn
  # -------------------------------------

  # optional("fontmgr_android")
  # optional("fontmgr_custom")
  # optional("fontmgr_custom_directory")
  # optional("fontmgr_custom_embedded")
  # optional("fontmgr_custom_empty")
  # optional("fontmgr_fontconfig")
  # optional("fontmgr_FontConfigInterface")
  # optional("fontmgr_mac_ct")
  # optional("fontmgr_win_gdi")

  # optional("gpu")
  if(skia_enable_gpu)
    install(
      DIRECTORY "${skia_SRC_DIR}/include/gpu"
      DESTINATION "${skia_INSTALL_INCLUDE_DIR}/include"
      FILES_MATCHING PATTERN "*.h"
    )
  endif()

  # optional("gif")
  # optional("heif")
  # optional("jpeg_decode")
  # optional("jpeg_encode")
  # optional("ndk_images")
  # optional("graphite")
  # optional("pdf")
  # optional("xps")
  # optional("png_decode")
  # optional("png_encode")
  # optional("raw")
  # optional("typeface_freetype")
  # optional("webp_decode")
  # optional("webp_encode")
  # optional("wuffs")
  # optional("xml")
  # optional("skvm_jit")


  #skia_component("skia")
  install(
    FILES "${skia_BUILD_DIR}/${skia_FILE_NAME}"
    DESTINATION "${skia_INSTALL_DLL_DIR}"
  )
  if(is_component_build AND is_win)
    install(
      FILES "${skia_BUILD_DIR}/${skia_DLL_LIB_FILE_NAME}"
      DESTINATION "${skia_INSTALL_LIB_DIR}"
    )
    install(
      FILES "$<$<CONFIG:Debug>:${skia_BUILD_DIR}/${skia_DLL_PDB_FILE_NAME}>"
      DESTINATION "${skia_INSTALL_PDB_DIR}"
    )
  endif()

  install(
    DIRECTORY
      "${skia_SRC_DIR}/include/c"
      "${skia_SRC_DIR}/include/codec"
      "${skia_SRC_DIR}/include/config"
      "${skia_SRC_DIR}/include/core"
      "${skia_SRC_DIR}/include/docs"
      "${skia_SRC_DIR}/include/effects"
      "${skia_SRC_DIR}/include/encode"
      "${skia_SRC_DIR}/include/pathops"
      "${skia_SRC_DIR}/include/ports"
      "${skia_SRC_DIR}/include/private"
      "${skia_SRC_DIR}/include/third_party"
      "${skia_SRC_DIR}/include/utils"
    DESTINATION "${skia_INSTALL_INCLUDE_DIR}/include"
    FILES_MATCHING PATTERN "*.h"
  )

  install(
    FILES
      "${skia_SRC_DIR}/src/core/SkLRUCache.h"
      "${skia_SRC_DIR}/src/core/SkTLazy.h"
    DESTINATION "${skia_INSTALL_INCLUDE_DIR}/src/core"
  )

  install(
    FILES
      "${skia_SRC_DIR}/src/sksl/SkSLLexer.h"
      "${skia_SRC_DIR}/src/sksl/SkSLModifiersPool.h"
      "${skia_SRC_DIR}/src/sksl/SkSLPool.h"
    DESTINATION "${skia_INSTALL_INCLUDE_DIR}/src/sksl"
  )

  install(
    FILES
      "${skia_SRC_DIR}/src/sksl/ir/SkSLExternalFunction.h"
    DESTINATION "${skia_INSTALL_INCLUDE_DIR}/src/sksl/ir"
  )

  install(
    FILES
      "${skia_SRC_DIR}/src/utils/SkJSON.h"
      "${skia_SRC_DIR}/src/utils/SkJSONWriter.h"
      "${skia_SRC_DIR}/src/utils/SkUTF.h"
    DESTINATION "${skia_INSTALL_INCLUDE_DIR}/src/utils"
  )

  #skia_static_library("pathkit")
  if(NOT is_component_build)
    install(
      FILES "${skia_BUILD_DIR}/${pathkit_FILE_NAME}"
      DESTINATION "${skia_INSTALL_LIB_DIR}"
    )
  endif()

  if(skia_enable_sksl)
    install(
      DIRECTORY "${skia_SRC_DIR}/include/sksl"
      DESTINATION "${skia_INSTALL_INCLUDE_DIR}/include"
      FILES_MATCHING PATTERN "*.h"
    )
  endif()

  if(is_android)
    install(
      DIRECTORY "${skia_SRC_DIR}/include/android"
      DESTINATION "${skia_INSTALL_INCLUDE_DIR}/include"
      FILES_MATCHING PATTERN "*.h"
    )
  endif()

  # -------------------------------------
  # END of BUILD.gn
  # -------------------------------------


  # -------------------------------------
  # experimental/ffmpeg/BUILD.gn
  # -------------------------------------
  if(NOT is_component_build AND skia_use_ffmpeg)
    install(
      FILES
        "${skia_BUILD_DIR}/${video_decoder_FILE_NAME}"
        "${skia_BUILD_DIR}/${video_encoder_FILE_NAME}"
      DESTINATION "${skia_INSTALL_LIB_DIR}"
    )
  endif()


  # -------------------------------------
  # experimental/sktext/BUILD.gn
  # -------------------------------------
  #component("sktext")
  if(skia_enable_sktext AND skia_enable_skshaper AND skia_use_icu
      AND skia_use_harfbuzz)
    install(
      FILES "${skia_BUILD_DIR}/${sktext_FILE_NAME}"
      DESTINATION "${skia_INSTALL_DLL_DIR}"
    )
    install(
      DIRECTORY "${skia_SRC_DIR}/experimental/sktext/include"
      DESTINATION "${skia_INSTALL_EXPERIMENTAL_DIR}/sktext"
      FILES_MATCHING PATTERN "*.h"
    )
    if(is_component_build AND is_win)
      #install(
      #  FILES "${skia_BUILD_DIR}/${sktext_DLL_LIB_FILE_NAME}"
      #  DESTINATION "${skia_INSTALL_LIB_DIR}"
      #)
      install(
        FILES "$<$<CONFIG:Debug>:${skia_BUILD_DIR}/${sktext_DLL_PDB_FILE_NAME}>"
        DESTINATION "${skia_INSTALL_PDB_DIR}"
      )
    endif()
  endif()


  # -------------------------------------
  # modules/particles/BUILD.gn
  # -------------------------------------
  #static_library("particles")
  if(skia_enable_particles)
    if(NOT is_component_build)
      install(
        FILES "${skia_BUILD_DIR}/${particles_FILE_NAME}"
        DESTINATION "${skia_INSTALL_LIB_DIR}"
      )
    endif()
    install(
      DIRECTORY "${skia_SRC_DIR}/modules/particles/include"
      DESTINATION "${skia_INSTALL_MODULES_DIR}/particles"
      FILES_MATCHING PATTERN "*.h"
    )
  endif()


  # -------------------------------------
  # modules/skottie/BUILD.gn
  # -------------------------------------
  # skia_component("skottie")
  if(skia_enable_skottie)
    install(
      FILES "${skia_BUILD_DIR}/${skottie_FILE_NAME}"
      DESTINATION "${skia_INSTALL_LIB_DIR}"
    )
    install(
      DIRECTORY "${skia_SRC_DIR}/modules/skottie/include"
      DESTINATION "${skia_INSTALL_MODULES_DIR}/skottie"
      FILES_MATCHING PATTERN "*.h"
    )
  endif()


  # -------------------------------------
  # modules/skparagraph/BUILD.gn
  # -------------------------------------
  # skia_component("skparagraph")
  if(skia_enable_skparagraph AND skia_enable_skshaper AND skia_use_icu
      AND skia_use_harfbuzz)
    install(
      FILES "${skia_BUILD_DIR}/${skparagraph_FILE_NAME}"
      DESTINATION "${skia_INSTALL_DLL_DIR}"
    )
    install(
      DIRECTORY "${skia_SRC_DIR}/modules/skparagraph/include"
      DESTINATION "${skia_INSTALL_MODULES_DIR}/skparagraph"
      FILES_MATCHING PATTERN "*.h"
    )
    if(is_component_build AND is_win)
      #install(
      #  FILES "${skia_BUILD_DIR}/${skparagraph_DLL_LIB_FILE_NAME}"
      #  DESTINATION "${skia_INSTALL_LIB_DIR}"
      #)
      install(
        FILES "$<$<CONFIG:Debug>:${skia_BUILD_DIR}/${skparagraph_DLL_PDB_FILE_NAME}>"
        DESTINATION "${skia_INSTALL_PDB_DIR}"
      )
    endif()
  endif()


  # -------------------------------------
  # modules/skplaintexteditor/BUILD.gn
  # -------------------------------------
  # NOTE: This is application
  #if(skia_use_icu AND skia_use_harfbuzz)
    #install(
    #  DIRECTORY "${skia_SRC_DIR}/modules/skplaintexteditor/include"
    #  DESTINATION "${skia_INSTALL_MODULES_DIR}/skplaintexteditor"
    #  FILES_MATCHING PATTERN "*.h"
    #)
  #endif()


  # -------------------------------------
  # modules/skresources/BUILD.gn
  # -------------------------------------
  # static_library("skresources")
  if(NOT is_component_build)
    install(
      FILES "${skia_BUILD_DIR}/${skresources_FILE_NAME}"
      DESTINATION "${skia_INSTALL_LIB_DIR}"
    )
  endif()
  install(
    DIRECTORY "${skia_SRC_DIR}/modules/skresources/include"
    DESTINATION "${skia_INSTALL_MODULES_DIR}/skresources"
    FILES_MATCHING PATTERN "*.h"
  )


  # -------------------------------------
  # modules/sksg/BUILD.gn
  # -------------------------------------
  # skia_component("sksg")
  if(skia_enable_skottie)
    install(
      FILES "${skia_BUILD_DIR}/${sksg_FILE_NAME}"
      DESTINATION "${skia_INSTALL_LIB_DIR}"
    )
    install(
      DIRECTORY "${skia_SRC_DIR}/modules/sksg/include"
      DESTINATION "${skia_INSTALL_MODULES_DIR}/sksg"
      FILES_MATCHING PATTERN "*.h"
    )
  endif()


  # -------------------------------------
  # modules/skshaper/BUILD.gn
  # -------------------------------------
  # component("skshaper")
  if(skia_enable_skshaper)
    install(
      FILES "${skia_BUILD_DIR}/${skshaper_FILE_NAME}"
      DESTINATION "${skia_INSTALL_DLL_DIR}"
    )
    install(
      DIRECTORY "${skia_SRC_DIR}/modules/skshaper/include"
      DESTINATION "${skia_INSTALL_MODULES_DIR}/skshaper"
      FILES_MATCHING PATTERN "*.h"
    )
    if(is_component_build AND is_win)
      install(
        FILES "${skia_BUILD_DIR}/${skshaper_DLL_LIB_FILE_NAME}"
        DESTINATION "${skia_INSTALL_LIB_DIR}"
      )
      install(
        FILES "$<$<CONFIG:Debug>:${skia_BUILD_DIR}/${skshaper_DLL_PDB_FILE_NAME}>"
        DESTINATION "${skia_INSTALL_PDB_DIR}"
      )
    endif()
  endif()


  # -------------------------------------
  # modules/skunicode/BUILD.gn
  # -------------------------------------
  # component("skunicode")
  if(skia_use_icu)
    install(
      FILES "${skia_BUILD_DIR}/${skunicode_FILE_NAME}"
      DESTINATION "${skia_INSTALL_DLL_DIR}"
    )
    install(
      DIRECTORY "${skia_SRC_DIR}/modules/skunicode/include"
      DESTINATION "${skia_INSTALL_MODULES_DIR}/skunicode"
      FILES_MATCHING PATTERN "*.h"
    )
    if(is_component_build AND is_win)
      install(
        FILES "${skia_BUILD_DIR}/${skunicode_DLL_LIB_FILE_NAME}"
        DESTINATION "${skia_INSTALL_LIB_DIR}"
      )
      install(
        FILES "$<$<CONFIG:Debug>:${skia_BUILD_DIR}/${skunicode_DLL_PDB_FILE_NAME}>"
        DESTINATION "${skia_INSTALL_PDB_DIR}"
      )
    endif()
  endif()


  # -------------------------------------
  # modules/svg/BUILD.gn
  # -------------------------------------
  # skia_component("svg")
  if(skia_enable_svg AND skia_use_expat)
    install(
      FILES "${skia_BUILD_DIR}/${svg_FILE_NAME}"
      DESTINATION "${skia_INSTALL_LIB_DIR}"
    )
    install(
      DIRECTORY "${skia_SRC_DIR}/include/svg"
      DESTINATION "${skia_INSTALL_INCLUDE_DIR}/include"
      FILES_MATCHING PATTERN "*.h"
    )
    install(
      DIRECTORY "${skia_SRC_DIR}/modules/svg/include"
      DESTINATION "${skia_INSTALL_MODULES_DIR}/svg"
      FILES_MATCHING PATTERN "*.h"
    )
  endif()


  # -------------------------------------
  # config.cmake
  # -------------------------------------
  include(CMakePackageConfigHelpers)
  configure_package_config_file(
    "${CMAKE_CURRENT_LIST_DIR}/SkiaConfig.in.cmake"
    "${skia_CMAKE_GEN_DIR}/SkiaConfig.gen.cmake"
    INSTALL_DESTINATION "${skia_INSTALL_LIB_DIR}/cmake/Skia"
    PATH_VARS
      skia_INSTALL_INCLUDE_DIR
      skia_INSTALL_EXPERIMENTAL_DIR
      skia_INSTALL_MODULES_DIR
      skia_INSTALL_BIN_DIR
      skia_INSTALL_DLL_DIR
      skia_INSTALL_LIB_DIR
      skia_INSTALL_PDB_DIR
  )
  write_basic_package_version_file(
    "${skia_CMAKE_GEN_DIR}/SkiaConfigVersion.cmake"
    VERSION ${lib_VERSION}
    COMPATIBILITY "SameMajorVersion"
  )

  file(GENERATE
    OUTPUT "${skia_CMAKE_GEN_DIR}/SkiaConfig.cmake"
    INPUT "${skia_CMAKE_GEN_DIR}/SkiaConfig.gen.cmake"
    NO_SOURCE_PERMISSIONS
    NEWLINE_STYLE UNIX
  )
  install(
    FILES
      "${skia_CMAKE_GEN_DIR}/SkiaConfig.cmake"
      "${skia_CMAKE_GEN_DIR}/SkiaConfigVersion.cmake"
    DESTINATION "${skia_INSTALL_LIB_DIR}/cmake/Skia"
  )


  cmake_policy(POP)
