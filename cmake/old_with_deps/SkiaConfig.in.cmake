@PACKAGE_INIT@

#
# CMakePackageConfigHelpers
# -------------------------------------



#-----------------------------------------------------------------------
# Find external libraries and set public defines
#

# NOTE: Use pattern '*.gn*' for search of usage of options in Skia source tree.

set(lib_PFX "@lib_PFX@")
set(lib_SFX "@lib_SFX@")

set(skia_INCLUDE_DIR "@PACKAGE_skia_INSTALL_INCLUDE_DIR@")
set(skia_EXPERIMENTAL_DIR "@PACKAGE_skia_INSTALL_EXPERIMENTAL_DIR@")
set(skia_MODULES_DIR "@PACKAGE_skia_INSTALL_MODULES_DIR@")
set(skia_BIN_DIR "@PACKAGE_skia_INSTALL_BIN_DIR@")
set(skia_DLL_DIR "@PACKAGE_skia_INSTALL_DLL_DIR@")
set(skia_LIB_DIR "@PACKAGE_skia_INSTALL_LIB_DIR@")
set(skia_PDB_DIR "@PACKAGE_skia_INSTALL_PDB_DIR@")

#if(is_win)
if(@is_win@)
  if(cmr_WINDOWS_KITS_DIR)
    set(_win_kit_dir "${cmr_WINDOWS_KITS_DIR}")
  else()
    set(_win_kit_dir "@cmr_WINDOWS_KITS_DIR@")
  endif()
  if(cmr_WINDOWS_KITS_VERSION)
    set(_win_kit_ver "${cmr_WINDOWS_KITS_VERSION}")
  else()
    set(_win_kit_ver "@cmr_WINDOWS_KITS_VERSION@")
  endif()
  set(_win_kit_arch "@target_cpu@")

  include(cmr_msvc_utils)
  get_windows_kits_library_dirs(${_win_kit_dir} ${_win_kit_ver} ${_win_kit_arch} _windows_kits_library_dirs)
endif()

macro(skia_find_library name)
  if(NOT TARGET "SkiaInternal_${name}")
    find_library(${name}_LIB
      NAMES "${name}"
      REQUIRED
    )
    add_library("SkiaInternal_${name}" UNKNOWN IMPORTED)
    set_target_properties("SkiaInternal_${name}" PROPERTIES
      IMPORTED_LOCATION "${${name}_LIB}"
    )
  endif()
endmacro()

macro(skia_find_library_win name)
  if(NOT TARGET "SkiaInternal_${name}")
    find_library(${name}_LIB
      NAMES "${name}.lib"
      PATHS ${_windows_kits_library_dirs}
      REQUIRED
    )
    add_library("SkiaInternal_${name}" UNKNOWN IMPORTED)
    set_target_properties("SkiaInternal_${name}" PROPERTIES
      IMPORTED_LOCATION "${${name}_LIB}"
    )
  endif()
endmacro()

macro(skia_find_framework name)
  if(NOT TARGET "SkiaInternal_${name}")
    find_library(${name}_LIB
      NAMES "${name}"
      REQUIRED
    )

    if(${name}_LIB MATCHES "/([^/]+)\\.framework$")
      set(${name}_LIB_FW "${${name}_LIB}/${CMAKE_MATCH_1}")
      if(EXISTS "${${name}_LIB_FW}.tbd")
        string(APPEND ${name}_LIB_FW ".tbd")
      endif()
      set(${name}_LIB "${${name}_LIB_FW}")
    endif()

    add_library("SkiaInternal_${name}" UNKNOWN IMPORTED)
    set_target_properties("SkiaInternal_${name}" PROPERTIES
      IMPORTED_LOCATION "${${name}_LIB}"
    )
  endif()
endmacro()

macro(skia_set_target_properties name)
  #if(NOT is_component_build)
  if(NOT @is_component_build@)
    set_target_properties(${name} PROPERTIES
      IMPORTED_NO_SONAME ON
      INTERFACE_COMPILE_FEATURES "cxx_std_17"
      IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
    )
  endif()
endmacro()

macro(skia_add_interface_link_libraries _target _lib)
  if(TARGET ${_lib})
    set_property(TARGET ${_target} APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES ${_lib}
    )
  endif()
endmacro()

macro(skia_add_interface_link_libraries_required _target _lib)
  if(NOT TARGET ${_lib})
    message(FATAL_ERROR "Target ${_lib} is not exist.")
  endif()
  set_property(TARGET ${_target} APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES ${_lib}
  )
endmacro()

macro(skia_set_imported_location _target _type _path)
  add_library(${_target}_imported ${_type} IMPORTED)
  set_property(TARGET ${_target}_imported APPEND PROPERTY
    IMPORTED_LOCATION ${_path}
  )
  set_property(TARGET ${_target} APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES ${_target}_imported
  )
endmacro()


#if(BUILD_SHARED_LIBS)
if(@BUILD_SHARED_LIBS@)
  set(lib_type SHARED)
else()
  set(lib_type STATIC)
endif()


# -------------------------------------
# third_party/BUILD.gn
# -------------------------------------
add_library(SkiaInternal_fontconfig INTERFACE)

#if(skia_use_fontconfig)
if(@skia_use_fontconfig@)
  find_library(fontconfig_LIB
    NAMES "fontconfig"
    REQUIRED
  )
  skia_set_imported_location(SkiaInternal_fontconfig UNKNOWN
    "${fontconfig_LIB}"
  )
endif()


# -------------------------------------
# third_party/brotli/BUILD.gn
# -------------------------------------
# The only consumer of brotli is freetype and it only needs to decode brotli.
add_library(SkiaInternal_brotli INTERFACE)

#if(NOT is_component_build AND skia_use_freetype_woff2)
if(NOT @is_component_build@ AND @skia_use_freetype_woff2@)
  skia_set_target_properties(SkiaInternal_brotli)
  set_and_check(brotli_LIB "${skia_LIB_DIR}/@brotli_FILE_NAME@")
  skia_set_imported_location(SkiaInternal_brotli STATIC
    "${brotli_LIB}"
  )
endif()


# -------------------------------------
# third_party/cpu-features/BUILD.gn
# -------------------------------------
add_library(SkiaInternal_cpu_features INTERFACE)


# -------------------------------------
# third_party/expat/BUILD.gn
# -------------------------------------
set(expat_TYPE UNKNOWN)

#if(skia_use_expat)
if(@skia_use_expat@)
  #if(skia_use_system_expat)
  if(@skia_use_system_expat@)
    find_library(expat_LIB
      NAMES "expat"
      REQUIRED
    )
  #elseif(NOT is_component_build)
  elseif(NOT @is_component_build@)
    set_and_check(expat_LIB "${skia_LIB_DIR}/@expat_FILE_NAME@")
    set(expat_TYPE STATIC)
  endif()
endif()

add_library(SkiaInternal_expat INTERFACE)

#if(skia_use_expat AND expat_LIB)
if(@skia_use_expat@ AND expat_LIB)
  #if(NOT skia_use_system_expat)
  if(NOT @skia_use_system_expat@)
    skia_set_target_properties(SkiaInternal_expat)
  endif()
  skia_set_imported_location(SkiaInternal_expat ${expat_TYPE}
    "${expat_LIB}"
  )
endif()


# -------------------------------------
# third_party/harfbuzz/BUILD.gn
# -------------------------------------
set(harfbuzz_TYPE UNKNOWN)

#if(skia_use_harfbuzz)
if(@skia_use_harfbuzz@)
  #if(skia_use_system_harfbuzz)
  if(@skia_use_system_harfbuzz@)
    find_library(harfbuzz_LIB
      NAMES "harfbuzz"
      REQUIRED
    )
  #elseif(NOT is_component_build)
  elseif(NOT @is_component_build@)
    set_and_check(harfbuzz_LIB "${skia_LIB_DIR}/@harfbuzz_FILE_NAME@")
    set(harfbuzz_TYPE STATIC)
  endif()
endif()

add_library(SkiaInternal_harfbuzz INTERFACE)

#if(skia_use_harfbuzz AND harfbuzz_LIB)
if(@skia_use_harfbuzz@ AND harfbuzz_LIB)
  #if(skia_use_system_harfbuzz)
  if(@skia_use_system_harfbuzz@)

    #if(skia_pdf_subset_harfbuzz)
    if(@skia_pdf_subset_harfbuzz@)
      skia_find_library("harfbuzz-subset")
      set_property(TARGET SkiaInternal_harfbuzz APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES SkiaInternal_harfbuzz-subset
      )
    endif()

  else()
    skia_set_target_properties(SkiaInternal_harfbuzz)
  endif()

  skia_set_imported_location(SkiaInternal_harfbuzz ${harfbuzz_TYPE}
    "${harfbuzz_LIB}"
  )
endif()


# -------------------------------------
# third_party/icu/BUILD.gn
# -------------------------------------
set(icu_TYPE UNKNOWN)

#if(skia_use_icu)
if(@skia_use_icu@)
  #if(skia_use_system_icu)
  if(@skia_use_system_icu@)
    find_library(icu_LIB
      NAMES "icuuc"
      REQUIRED
    )
  else()
    add_library(Skia::icudata UNKNOWN IMPORTED)
    set_and_check(icudata_LIB "${skia_DLL_DIR}/@icudata_FILE_NAME@")
    set_target_properties(Skia::icudata PROPERTIES
      IMPORTED_LOCATION "${icudata_LIB}"
      IMPORTED_NO_SONAME ON
    )

    #if(NOT is_component_build)
    if(NOT @is_component_build@)
      set_and_check(icu_LIB "${skia_LIB_DIR}/@icu_FILE_NAME@")
      set(icu_TYPE STATIC)
    endif()
  endif()
endif()

add_library(SkiaInternal_icu INTERFACE)

#if(skia_use_icu AND icu_LIB)
if(@skia_use_icu@ AND icu_LIB)
  #if(NOT skia_use_system_icu)
  if(NOT @skia_use_system_icu@)
    skia_set_target_properties(SkiaInternal_icu)

    #if(is_win)
    if(@is_win@)
      skia_find_library_win("Advapi32")
      set_property(TARGET SkiaInternal_icu APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES SkiaInternal_Advapi32
      )
    endif()

  endif()

  skia_set_imported_location(SkiaInternal_icu ${icu_TYPE}
    "${icu_LIB}"
  )
endif()


# -------------------------------------
# third_party/libjpeg-turbo/BUILD.gn
# -------------------------------------
set(libjpeg_TYPE UNKNOWN)

# TODO:
#if(skia_use_libjpeg_turbo_decode OR skia_use_libjpeg_turbo_encode AND
#    NOT skia_use_system_libjpeg_turbo NOT is_component_build)

#if(skia_use_system_libjpeg_turbo)
if(@skia_use_system_libjpeg_turbo@)
  find_library(libjpeg_LIB
    NAMES "jpeg"
    REQUIRED
  )
#elseif(NOT is_component_build)
elseif(NOT @is_component_build@)
  set_and_check(libjpeg_LIB "${skia_LIB_DIR}/@libjpeg_FILE_NAME@")
  set(libjpeg_TYPE STATIC)
endif()

add_library(SkiaInternal_libjpeg INTERFACE)

if(libjpeg_LIB)
  #if(NOT skia_use_system_libjpeg_turbo)
  if(NOT @skia_use_system_libjpeg_turbo@)
    skia_set_target_properties(SkiaInternal_libjpeg)
  endif()
  skia_set_imported_location(SkiaInternal_libjpeg ${libjpeg_TYPE}
    "${libjpeg_LIB}"
  )
endif()


# -------------------------------------
# third_party/piex/BUILD.gn
# -------------------------------------
add_library(SkiaInternal_piex INTERFACE)

#if(skia_use_piex AND NOT is_component_build)
if(@skia_use_piex@ AND NOT @is_component_build@)
  skia_set_target_properties(SkiaInternal_piex)
  set_and_check(piex_LIB "${skia_LIB_DIR}/@piex_FILE_NAME@")
  skia_set_imported_location(SkiaInternal_piex STATIC
    "${piex_LIB}"
  )
endif()


# -------------------------------------
# third_party/spirv-cross/BUILD.gn
# -------------------------------------
add_library(SkiaInternal_spirv_cross INTERFACE)

#if(NOT is_component_build AND skia_enable_gpu AND skia_use_direct3d)
if(NOT @is_component_build@ AND @skia_enable_gpu@ AND @skia_use_direct3d@)
  skia_set_target_properties(SkiaInternal_spirv_cross)
  set_and_check(spirv_cross_LIB "${skia_LIB_DIR}/@spirv_cross_FILE_NAME@")
  skia_set_imported_location(SkiaInternal_spirv_cross STATIC
    "${spirv_cross_LIB}"
  )
endif()


# -------------------------------------
# third_party/zlib/BUILD.gn
# -------------------------------------
set(zlib_TYPE UNKNOWN)

#if(skia_use_zlib)
if(@skia_use_zlib@)
  #if(skia_use_system_zlib)
  if(@skia_use_system_zlib@)
    find_library(zlib_LIB
      NAMES "z"
      REQUIRED
    )
  #elseif(NOT is_component_build)
  elseif(NOT @is_component_build@)
    set_and_check(zlib_LIB "${skia_LIB_DIR}/@zlib_FILE_NAME@")
    set(zlib_TYPE STATIC)
  endif()
endif()

add_library(SkiaInternal_zlib INTERFACE)

#if(skia_use_zlib AND zlib_LIB)
if(@skia_use_zlib@ AND zlib_LIB)
  #if(NOT skia_use_system_zlib)
  if(NOT @skia_use_system_zlib@)
    skia_set_target_properties(SkiaInternal_zlib)
    #if(is_android)
    if(@is_android@)
      set_property(TARGET SkiaInternal_zlib APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES SkiaInternal_cpu_features
      )
    endif()
  endif()
  skia_set_imported_location(SkiaInternal_zlib ${zlib_TYPE}
    "${zlib_LIB}"
  )
endif()

add_library(SkiaInternal_compression_utils_portable INTERFACE)

#if(skia_use_zlib AND NOT is_component_build)
if(@skia_use_zlib@ AND NOT @is_component_build@)
  skia_set_target_properties(SkiaInternal_compression_utils_portable)
  set_and_check(compression_utils_portable_LIB
    "${skia_LIB_DIR}/@compression_utils_portable_FILE_NAME@"
  )
  set_property(TARGET SkiaInternal_compression_utils_portable APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES SkiaInternal_zlib  # either system or from source
  )
  skia_set_imported_location(SkiaInternal_compression_utils_portable STATIC
    "${compression_utils_portable_LIB}"
  )
endif()


# -------------------------------------
# third_party/dng_sdk/BUILD.gn
# -------------------------------------
add_library(SkiaInternal_dng_sdk INTERFACE)

#if(NOT is_component_build AND skia_use_dng_sdk)
if(NOT @is_component_build@ AND @skia_use_dng_sdk@)
  skia_set_target_properties(SkiaInternal_dng_sdk)
  set_and_check(dng_sdk_LIB "${skia_LIB_DIR}/@dng_sdk_FILE_NAME@")
  set_property(TARGET SkiaInternal_dng_sdk APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES SkiaInternal_libjpeg SkiaInternal_zlib
  )
  skia_set_imported_location(SkiaInternal_dng_sdk STATIC
    "${dng_sdk_LIB}"
  )
endif()


# -------------------------------------
# third_party/libpng/BUILD.gn
# -------------------------------------
set(libpng_TYPE UNKNOWN)

# TODO:
#if(skia_use_libpng_decode OR skia_use_libpng_encode AND
#    NOT skia_use_system_libpng NOT is_component_build)

#if(skia_use_system_libpng)
if(@skia_use_system_libpng@)
  find_library(libpng_LIB
    NAMES "png"
    REQUIRED
  )
#elseif(NOT is_component_build)
elseif(NOT @is_component_build@)
  set_and_check(libpng_LIB "${skia_LIB_DIR}/@libpng_FILE_NAME@")
  set(libpng_TYPE STATIC)
endif()

add_library(SkiaInternal_libpng INTERFACE)

if(libpng_LIB)
  #if(NOT skia_use_system_libpng)
  if(NOT @skia_use_system_libpng@)
    skia_set_target_properties(SkiaInternal_libpng)
    set_property(TARGET SkiaInternal_libpng APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES SkiaInternal_zlib
    )
  endif()
  skia_set_imported_location(SkiaInternal_libpng ${libpng_TYPE}
    "${libpng_LIB}"
  )
endif()


# -------------------------------------
# third_party/freetype2/BUILD.gn
# -------------------------------------
set(freetype2_TYPE UNKNOWN)

#if(skia_use_freetype)
if(@skia_use_freetype@)
  #if(skia_use_system_freetype2)
  if(@skia_use_system_freetype2@)
    find_library(freetype2_LIB
      NAMES "freetype"
      REQUIRED
    )
  #elseif(NOT is_component_build)
  elseif(NOT @is_component_build@)
    set_and_check(freetype2_LIB "${skia_LIB_DIR}/@freetype2_FILE_NAME@")
    set(freetype2_TYPE STATIC)
  endif()
endif()

add_library(SkiaInternal_freetype2 INTERFACE)

#if(skia_use_freetype)
if(@skia_use_freetype@ AND freetype2_LIB)
  #if(NOT skia_use_system_freetype2)
  if(NOT @skia_use_system_freetype2@)
    skia_set_target_properties(SkiaInternal_freetype2)
    set_property(TARGET SkiaInternal_freetype2 APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES SkiaInternal_libpng
    )
    #if(skia_use_freetype_woff2)
    if(@skia_use_freetype_woff2@)
      set_property(TARGET SkiaInternal_freetype2 APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES SkiaInternal_brotli
      )
    endif()
  endif()
  skia_set_imported_location(SkiaInternal_freetype2 ${freetype2_TYPE}
    "${freetype2_LIB}"
  )
endif()


# -------------------------------------
# third_party/libwebp/BUILD.gn
# -------------------------------------
set(libwebp_TYPE UNKNOWN)

# TODO:
#if(skia_use_libwebp_decode OR skia_use_libwebp_encode AND
#    NOT skia_use_system_libwebp NOT is_component_build)

#if(skia_use_system_libwebp)
if(@skia_use_system_libwebp@)
  find_library(libwebp_LIB
    NAMES "webp"
    REQUIRED
  )
#elseif(NOT is_component_build)
elseif(NOT @is_component_build@)
  set_and_check(libwebp_LIB "${skia_LIB_DIR}/@libwebp_FILE_NAME@")
  set(libwebp_TYPE STATIC)
endif()

add_library(SkiaInternal_libwebp INTERFACE)

if(libwebp_LIB)
  #if(skia_use_system_libwebp)
  if(@skia_use_system_libwebp@)
    skia_find_library("webpdemux")
    skia_find_library("webpmux")
    set_property(TARGET SkiaInternal_libwebp APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES SkiaInternal_webpdemux SkiaInternal_webpmux
    )

  else()
    add_library(SkiaInternal_libwebp_sse41 STATIC IMPORTED)
    skia_set_target_properties(SkiaInternal_libwebp_sse41)
    set_and_check(libwebp_sse41_LIB "${skia_LIB_DIR}/@libwebp_sse41_FILE_NAME@")
    set_target_properties(SkiaInternal_libwebp_sse41 PROPERTIES
      IMPORTED_LOCATION "${libwebp_sse41_LIB}"
    )

    skia_set_target_properties(SkiaInternal_libwebp)
    set_property(TARGET SkiaInternal_libwebp APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES SkiaInternal_libwebp_sse41
    )

    #if(is_android)
    if(@is_android@)
      set_property(TARGET SkiaInternal_libwebp APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES SkiaInternal_cpu_features
      )
    endif()
  endif()

  skia_set_imported_location(SkiaInternal_libwebp ${libwebp_TYPE}
    "${libwebp_LIB}"
  )
endif()


# -------------------------------------
# third_party/sfntly/BUILD.gn
# -------------------------------------
add_library(SkiaInternal_sfntly INTERFACE)

#if(NOT is_component_build
#    AND skia_use_zlib AND skia_enable_pdf AND skia_use_icu
#    AND NOT skia_use_harfbuzz AND skia_use_sfntly)
if(NOT @is_component_build@
    AND @skia_use_zlib@ AND @skia_enable_pdf@ AND @skia_use_icu@
    AND NOT @skia_use_harfbuzz@ AND @skia_use_sfntly@)
  skia_set_target_properties(SkiaInternal_sfntly)
  set_and_check(sfntly_LIB "${skia_LIB_DIR}/@sfntly_FILE_NAME@")
  set_property(TARGET SkiaInternal_sfntly APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES SkiaInternal_icu
  )
  skia_set_imported_location(SkiaInternal_sfntly STATIC
    "${sfntly_LIB}"
  )
endif()


# -------------------------------------
# gn/skia/BUILD.gn
# -------------------------------------

add_library(SkiaInternal_default INTERFACE)

#if(NOT is_component_build)
if(NOT @is_component_build@)
  #if(is_ios)
  if(@is_ios@)
    skia_find_library("objc")
    set_property(TARGET SkiaInternal_default APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES SkiaInternal_objc
    )
  endif()

  #if(is_linux)
  if(@is_linux@)
    skia_find_library("pthread")
    set_property(TARGET SkiaInternal_default APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES SkiaInternal_pthread
    )
  endif()
endif()


# -------------------------------------
# BUILD.gn
# -------------------------------------

# optional("fontmgr_android")
add_library(SkiaInternal_fontmgr_android INTERFACE)
#if(NOT is_component_build AND skia_enable_fontmgr_android)
if(NOT @is_component_build@ AND @skia_enable_fontmgr_android@)
  set_property(TARGET SkiaInternal_fontmgr_android APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES SkiaInternal_typeface_freetype SkiaInternal_expat
  )
endif()

# optional("fontmgr_custom")
add_library(SkiaInternal_fontmgr_custom INTERFACE)
#if(NOT is_component_build AND
#    (skia_enable_fontmgr_custom_directory OR
#    skia_enable_fontmgr_custom_embedded OR
#    skia_enable_fontmgr_custom_empty))
if(NOT @is_component_build@ AND
    (@skia_enable_fontmgr_custom_directory@ OR
    @skia_enable_fontmgr_custom_embedded@ OR
    @skia_enable_fontmgr_custom_empty@))
  set_property(TARGET SkiaInternal_fontmgr_custom APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES SkiaInternal_typeface_freetype
  )
endif()

# optional("fontmgr_custom_directory")
add_library(SkiaInternal_fontmgr_custom_directory INTERFACE)
#if(NOT is_component_build AND skia_enable_fontmgr_custom_directory)
if(NOT @is_component_build@ AND @skia_enable_fontmgr_custom_directory@)
  set_property(TARGET SkiaInternal_fontmgr_custom_directory APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES SkiaInternal_fontmgr_custom SkiaInternal_typeface_freetype
  )
endif()

# optional("fontmgr_custom_embedded")
add_library(SkiaInternal_fontmgr_custom_embedded INTERFACE)
#if(NOT is_component_build AND skia_enable_fontmgr_custom_embedded)
if(NOT @is_component_build@ AND @skia_enable_fontmgr_custom_embedded@)
  set_property(TARGET SkiaInternal_fontmgr_custom_embedded APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES SkiaInternal_fontmgr_custom SkiaInternal_typeface_freetype
  )
endif()

# optional("fontmgr_custom_empty")
add_library(SkiaInternal_fontmgr_custom_empty INTERFACE)
#if(NOT is_component_build AND skia_enable_fontmgr_custom_empty)
if(NOT @is_component_build@ AND @skia_enable_fontmgr_custom_empty@)
  set_property(TARGET SkiaInternal_fontmgr_custom_empty APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES SkiaInternal_fontmgr_custom SkiaInternal_typeface_freetype
  )
endif()

# optional("fontmgr_fontconfig")
add_library(SkiaInternal_fontmgr_fontconfig INTERFACE)
#if(NOT is_component_build AND skia_enable_fontmgr_fontconfig)
if(NOT @is_component_build@ AND @skia_enable_fontmgr_fontconfig@)
  set_property(TARGET SkiaInternal_fontmgr_fontconfig APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES SkiaInternal_typeface_freetype
  )
endif()

# optional("fontmgr_FontConfigInterface")
add_library(SkiaInternal_fontmgr_FontConfigInterface INTERFACE)
#if(NOT is_component_build AND skia_enable_fontmgr_FontConfigInterface)
if(NOT @is_component_build@ AND @skia_enable_fontmgr_FontConfigInterface@)
  set_property(TARGET SkiaInternal_fontmgr_FontConfigInterface APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      SkiaInternal_typeface_freetype
      SkiaInternal_fontconfig
  )
endif()

# optional("fontmgr_mac_ct")
add_library(SkiaInternal_fontmgr_mac_ct INTERFACE)
#if(NOT is_component_build AND skia_use_fonthost_mac)
if(NOT @is_component_build@ AND @skia_use_fonthost_mac@)
  #if(is_mac)
  if(@is_mac@)
    # AppKit symbols NSFontWeightXXX may be dlsym'ed.
    skia_find_framework("AppKit")
    skia_find_framework("ApplicationServices")
    set_property(TARGET SkiaInternal_fontmgr_mac_ct APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES
        SkiaInternal_AppKit
        SkiaInternal_ApplicationServices
    )
  endif()

  #if(is_ios)
  if(@is_ios@)
    skia_find_framework("CoreFoundation")
    skia_find_framework("CoreGraphics")
    skia_find_framework("CoreText")
    skia_find_framework("UIKit")
    set_property(TARGET SkiaInternal_fontmgr_mac_ct APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES
        SkiaInternal_CoreFoundation
        SkiaInternal_CoreGraphics
        SkiaInternal_CoreText
        # UIKit symbols UIFontWeightXXX may be dlsym'ed.
        SkiaInternal_UIKit
    )
  endif()
endif()

# optional("fontmgr_win_gdi")
add_library(SkiaInternal_fontmgr_win_gdi INTERFACE)
#if(NOT is_component_build AND skia_enable_fontmgr_win_gdi)
if(NOT @is_component_build@ AND @skia_enable_fontmgr_win_gdi@)
  skia_find_library_win("Gdi32")
  set_property(TARGET SkiaInternal_fontmgr_win_gdi APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES SkiaInternal_Gdi32
  )
endif()


# optional("gpu")
add_library(SkiaInternal_gpu INTERFACE)
#if(skia_enable_gpu)
if(@skia_enable_gpu@)
  #if(skia_use_gl)
  if(@skia_use_gl@)
    set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
      INTERFACE_COMPILE_DEFINITIONS "SK_GL"
    )

    #if(NOT is_component_build)
    if(NOT @is_component_build@)
      #if(is_android)
      if(@is_android@)
        #if(DEFINED ndk_api AND ndk_api VERSION_GREATER_EQUAL 26)
        if("@ndk_api@" VERSION_GREATER_EQUAL 26)
          skia_find_library("android")
          set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
            INTERFACE_LINK_LIBRARIES SkiaInternal_android
          )
        endif()

      #elseif(skia_use_egl)
      elseif(@skia_use_egl@)
        skia_find_library("EGL")
        set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
          INTERFACE_LINK_LIBRARIES SkiaInternal_EGL
        )

      #elseif(is_linux AND skia_use_x11)
      elseif(@is_linux@ AND @skia_use_x11@)
        skia_find_library("GL")
        set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
          INTERFACE_LINK_LIBRARIES SkiaInternal_GL
        )

      #elseif(is_win AND NOT skia_enable_winuwp)
      elseif(@is_win@ AND NOT @skia_enable_winuwp@)
        #if(NOT target_cpu STREQUAL "arm64")
        if(NOT "@target_cpu@" STREQUAL "arm64")
          skia_find_library_win("OpenGL32")
          set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
            INTERFACE_LINK_LIBRARIES SkiaInternal_OpenGL32
          )
        endif()
      endif()
    endif()
  endif()

  #if(skia_use_vulkan)
  if(@skia_use_vulkan@)
    set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
      INTERFACE_COMPILE_DEFINITIONS "SK_VULKAN"
    )
    #if(skia_enable_vulkan_debug_layers)
    if(@skia_enable_vulkan_debug_layers@)
      set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
        INTERFACE_COMPILE_DEFINITIONS "SK_ENABLE_VK_LAYERS"
      )
    endif()
  endif()

  #if(is_android AND (skia_use_gl OR skia_use_vulkan))
  if(@is_android@ AND (@skia_use_gl@ OR @skia_use_vulkan@))
    # this lib is required to link against AHardwareBuffer
    #if(NOT is_component_build AND DEFINED ndk_api AND ndk_api VERSION_GREATER_EQUAL 26)
    if(NOT @is_component_build@ AND "@ndk_api@" VERSION_GREATER_EQUAL 26)
      skia_find_library("android")
      set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES SkiaInternal_android
      )
    endif()
  endif()

  #if(skia_use_direct3d)
  if(@skia_use_direct3d@)
    set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
      INTERFACE_COMPILE_DEFINITIONS "SK_DIRECT3D" "SK_ENABLE_SPIRV_CROSS"
    )

    #if(NOT is_component_build)
    if(NOT @is_component_build@)
      set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES
          SkiaInternal_d3d12allocator
          SkiaInternal_spirv_cross
      )
    endif()

    #if(skia_enable_direct3d_debug_layer)
    if(@skia_enable_direct3d_debug_layer@)
      set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
        INTERFACE_COMPILE_DEFINITIONS "SK_ENABLE_D3D_DEBUG_LAYER"
      )
    endif()

    #if(NOT is_component_build)
    if(NOT @is_component_build@)
      skia_find_library("d3d12")
      set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES SkiaInternal_d3d12
      )
      skia_find_library("dxgi")
      set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES SkiaInternal_dxgi
      )
      skia_find_library("d3dcompiler")
      set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES SkiaInternal_d3dcompiler
      )
    endif()
  endif()

  #if(skia_use_metal)
  if(@skia_use_metal@)
    set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
      INTERFACE_COMPILE_DEFINITIONS "SK_METAL"
    )

    #if(skia_enable_metal_debug_info)
    if(@skia_enable_metal_debug_info@)
      set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
        INTERFACE_COMPILE_DEFINITIONS "SK_ENABLE_MTL_DEBUG_INFO"
      )
    endif()

    #if(NOT is_component_build)
    if(NOT @is_component_build@)
      skia_find_framework("Metal")
      set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES SkiaInternal_Metal
      )
      skia_find_framework("Foundation")
      set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES SkiaInternal_Foundation
      )

      #if(is_ios)
      if(@is_ios@)
        skia_find_framework("UIKit")
        set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
          INTERFACE_LINK_LIBRARIES SkiaInternal_UIKit
        )
      endif()
    endif()
  endif()

  #if(is_debug)
  if(@is_debug@)
    set_property(TARGET SkiaInternal_gpu APPEND PROPERTY
      INTERFACE_COMPILE_DEFINITIONS "SK_ENABLE_DUMP_GPU"
    )
  endif()
endif()  # if(skia_enable_gpu)


# optional("gif")
add_library(SkiaInternal_gif INTERFACE)
#if(NOT skia_use_wuffs AND skia_use_libgifcodec)
if(NOT @skia_use_wuffs@ AND @skia_use_libgifcodec@)
  # TODO:
  #if("True" STREQUAL
  #    exec_script("gn/checkpath.py",
  #                [ rebase_path(_libgifcodec_gni_path, root_build_dir) ],
  #                "trim string"))
    set_property(TARGET SkiaInternal_gif APPEND PROPERTY
      INTERFACE_COMPILE_DEFINITIONS "SK_USE_LIBGIFCODEC"
    )
  #endif()
endif()

# optional("heif")
add_library(SkiaInternal_heif INTERFACE)
#if(skia_use_libheif)
if(@skia_use_libheif@)
  set_property(TARGET SkiaInternal_heif APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_HAS_HEIF_LIBRARY"
  )
endif()

# optional("jpeg_decode")
add_library(SkiaInternal_jpeg_decode INTERFACE)
#if(skia_use_libjpeg_turbo_decode)
if(@skia_use_libjpeg_turbo_decode@)
  #if(NOT is_component_build)
  if(NOT @is_component_build@)
    set_property(TARGET SkiaInternal_jpeg_decode APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES SkiaInternal_libjpeg
    )
  endif()

  set_property(TARGET SkiaInternal_jpeg_decode APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_CODEC_DECODES_JPEG"
  )
endif()

# optional("jpeg_encode")
add_library(SkiaInternal_jpeg_encode INTERFACE)
#if(skia_use_libjpeg_turbo_encode)
if(@skia_use_libjpeg_turbo_encode@)
  #if(NOT is_component_build)
  if(NOT @is_component_build@)
    set_property(TARGET SkiaInternal_jpeg_encode APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES SkiaInternal_libjpeg
    )
  endif()

  set_property(TARGET SkiaInternal_jpeg_encode APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_ENCODE_JPEG"
  )
endif()

# optional("ndk_images")
add_library(SkiaInternal_ndk_images INTERFACE)
#if(skia_use_ndk_images)
if(@skia_use_ndk_images@)
  #if(NOT is_component_build)
  if(NOT @is_component_build@)
    skia_find_library("jnigraphics")
    set_property(TARGET SkiaInternal_ndk_images APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES SkiaInternal_jnigraphics
    )
  endif()

  set_property(TARGET SkiaInternal_ndk_images APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_ENABLE_NDK_IMAGES"
  )
endif()

# optional("graphite")
add_library(SkiaInternal_graphite INTERFACE)
#if(skia_enable_graphite)
if(@skia_enable_graphite@)
  set_property(TARGET SkiaInternal_graphite APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_GRAPHITE_ENABLED"
  )

  #if(skia_use_metal)
  if(@skia_use_metal@)
    set_property(TARGET SkiaInternal_graphite APPEND PROPERTY
      INTERFACE_COMPILE_DEFINITIONS "SK_METAL"
    )

    #if(skia_enable_metal_debug_info)
    if(@skia_enable_metal_debug_info@)
      set_property(TARGET SkiaInternal_graphite APPEND PROPERTY
        INTERFACE_COMPILE_DEFINITIONS "SK_ENABLE_MTL_DEBUG_INFO"
      )
    endif()

    #if(NOT is_component_build)
    if(NOT @is_component_build@)
      skia_find_framework("Metal")
      set_property(TARGET SkiaInternal_graphite APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES SkiaInternal_Metal
      )

      skia_find_framework("Foundation")
      set_property(TARGET SkiaInternal_graphite APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES SkiaInternal_Foundation
      )
    endif()
  endif()
endif()

# optional("pdf")
add_library(SkiaInternal_pdf INTERFACE)
#if(skia_use_zlib AND skia_enable_pdf)
if(@skia_use_zlib@ AND @skia_enable_pdf@)
  #if(NOT is_component_build)
  if(NOT @is_component_build@)
    set_property(TARGET SkiaInternal_pdf APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES SkiaInternal_zlib
    )
  endif()

  set_property(TARGET SkiaInternal_pdf APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_SUPPORT_PDF"
  )

  #if(NOT is_component_build)
  if(NOT @is_component_build@)
    #if(skia_use_libjpeg_turbo_decode)
    if(@skia_use_libjpeg_turbo_decode@)
      set_property(TARGET SkiaInternal_pdf APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES SkiaInternal_jpeg_decode
      )
    endif()

    #if(skia_use_libjpeg_turbo_encode)
    if(@skia_use_libjpeg_turbo_encode@)
      set_property(TARGET SkiaInternal_pdf APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES SkiaInternal_jpeg_encode
      )
    endif()
  endif()

  #if(skia_use_icu)
  if(@skia_use_icu@)
    #if(skia_use_harfbuzz AND skia_pdf_subset_harfbuzz)
    if(@skia_use_harfbuzz@ AND @skia_pdf_subset_harfbuzz@)
      #if(NOT is_component_build)
      if(NOT @is_component_build@)
        set_property(TARGET SkiaInternal_pdf APPEND PROPERTY
          INTERFACE_LINK_LIBRARIES SkiaInternal_harfbuzz
        )
      endif()

      set_property(TARGET SkiaInternal_pdf APPEND PROPERTY
        INTERFACE_COMPILE_DEFINITIONS "SK_PDF_USE_HARFBUZZ_SUBSET"
      )

    #elseif(skia_use_sfntly)
    elseif(@skia_use_sfntly@)
      #if(NOT is_component_build)
      if(NOT @is_component_build@)
        set_property(TARGET SkiaInternal_pdf APPEND PROPERTY
          INTERFACE_LINK_LIBRARIES SkiaInternal_sfntly
        )
      endif()

      set_property(TARGET SkiaInternal_pdf APPEND PROPERTY
        INTERFACE_COMPILE_DEFINITIONS "SK_PDF_USE_SFNTLY"
      )
    endif()
  endif()
endif()

# optional("xps")
add_library(SkiaInternal_xps INTERFACE)
#if(skia_use_xps AND is_win)
if(@skia_use_xps@ AND @is_win@)
  set_property(TARGET SkiaInternal_xps APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_SUPPORT_XPS"
  )
endif()

# optional("png_decode")
add_library(SkiaInternal_png_decode INTERFACE)
#if(skia_use_libpng_decode)
if(@skia_use_libpng_decode@)
  #if(NOT is_component_build)
  if(NOT @is_component_build@)
    set_property(TARGET SkiaInternal_png_decode APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES SkiaInternal_libpng
    )
  endif()

  set_property(TARGET SkiaInternal_png_decode APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_CODEC_DECODES_PNG"
  )
endif()

# optional("png_encode")
add_library(SkiaInternal_png_encode INTERFACE)
#if(skia_use_libpng_encode)
if(@skia_use_libpng_encode@)
  #if(NOT is_component_build)
  if(NOT @is_component_build@)
    set_property(TARGET SkiaInternal_png_encode APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES SkiaInternal_libpng
    )
  endif()

  set_property(TARGET SkiaInternal_png_encode APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_ENCODE_PNG"
  )
endif()

# optional("raw")
add_library(SkiaInternal_raw INTERFACE)
#if(skia_use_dng_sdk AND skia_use_libjpeg_turbo_decode AND skia_use_piex)
if(@skia_use_dng_sdk@ AND @skia_use_libjpeg_turbo_decode@ AND @skia_use_piex@)
  #if(NOT is_component_build)
  if(NOT @is_component_build@)
    set_property(TARGET SkiaInternal_raw APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES
        SkiaInternal_dng_sdk
        SkiaInternal_libjpeg
        SkiaInternal_piex
    )
  endif()

  set_property(TARGET SkiaInternal_raw APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_CODEC_DECODES_RAW"
  )
endif()

# optional("typeface_freetype")
add_library(SkiaInternal_typeface_freetype INTERFACE)
#if(skia_use_freetype AND NOT is_component_build)
if(@skia_use_freetype@ AND NOT @is_component_build@)
  set_property(TARGET SkiaInternal_typeface_freetype APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES SkiaInternal_freetype2
  )
endif()

# optional("webp_decode")
add_library(SkiaInternal_webp_decode INTERFACE)
#if(skia_use_libwebp_decode)
if(@skia_use_libwebp_decode@)
  #if(NOT is_component_build)
  if(NOT @is_component_build@)
    set_property(TARGET SkiaInternal_webp_decode APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES SkiaInternal_libwebp
    )
  endif()

  set_property(TARGET SkiaInternal_webp_decode APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_CODEC_DECODES_WEBP"
  )
endif()

# optional("webp_encode")
add_library(SkiaInternal_webp_encode INTERFACE)
#if(skia_use_libwebp_encode)
if(@skia_use_libwebp_encode@)
  #if(NOT is_component_build)
  if(NOT @is_component_build@)
    set_property(TARGET SkiaInternal_webp_encode APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES SkiaInternal_libwebp
    )
  endif()

  set_property(TARGET SkiaInternal_webp_encode APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_ENCODE_WEBP"
  )
endif()

# optional("wuffs")
add_library(SkiaInternal_wuffs INTERFACE)
#if(skia_use_wuffs)
if(@skia_use_wuffs@)
  #if(NOT is_component_build)
  if(NOT @is_component_build@)
    set_property(TARGET SkiaInternal_wuffs APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES SkiaInternal_libwuffs
    )
  endif()

  set_property(TARGET SkiaInternal_wuffs APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_HAS_WUFFS_LIBRARY"
  )
endif()

# optional("xml")
add_library(SkiaInternal_xml INTERFACE)
#if(skia_use_expat)
if(@skia_use_expat@)
  #if(NOT is_component_build)
  if(NOT @is_component_build@)
    set_property(TARGET SkiaInternal_xml APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES SkiaInternal_expat
    )
  endif()

  set_property(TARGET SkiaInternal_xml APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_XML"
  )
endif()

# optional("skvm_jit") {
add_library(SkiaInternal_skvm_jit INTERFACE)
#if(skia_enable_skvm_jit_when_possible)
if(@skia_enable_skvm_jit_when_possible@)
  set_property(TARGET SkiaInternal_skvm_jit APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SKVM_JIT_WHEN_POSSIBLE"
  )
endif()


#skia_component("skia")
add_library(Skia::skia ${lib_type} IMPORTED)

skia_set_target_properties(Skia::skia)

set_and_check(skia_LIB "${skia_DLL_DIR}/@skia_FILE_NAME@")
set_target_properties(Skia::skia PROPERTIES
  IMPORTED_LOCATION "${skia_LIB}"
)
#if(is_win AND is_component_build)
if(@is_win@ AND @is_component_build@)
  set_and_check(skia_DLL_LIB "${skia_LIB_DIR}/@skia_DLL_LIB_FILE_NAME@")
  set_target_properties(Skia::skia PROPERTIES
    IMPORTED_IMPLIB "${skia_DLL_LIB}"
  )
endif()

# Skia public API, generally provided by :skia.
#config("skia_public")

#include_dirs = [ "." ]
set_property(TARGET Skia::skia APPEND PROPERTY
  INTERFACE_INCLUDE_DIRECTORIES "${skia_INCLUDE_DIR}"
)

#if(is_component_build)
if(@is_component_build@)
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SKIA_DLL"
  )
endif()
#if(is_fuchsia OR is_linux)
if(@is_fuchsia@ OR @is_linux@)
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_R32_SHIFT=16"
  )
endif()
#if(NOT skia_enable_gpu)
if(NOT @skia_enable_gpu@)
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_SUPPORT_GPU=0"
  )
endif()
#if(skia_enable_sksl)
if(@skia_enable_sksl@)
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_ENABLE_SKSL"
  )
endif()
#if(skia_gl_standard STREQUAL "gles")
if("@skia_gl_standard@" STREQUAL "gles")
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_ASSUME_GL_ES=1"
  )
#elseif(skia_gl_standard STREQUAL "gl")
elseif("@skia_gl_standard@" STREQUAL "gl")
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_ASSUME_GL=1"
  )
#elseif(skia_gl_standard STREQUAL "webgl")
elseif("@skia_gl_standard@" STREQUAL "webgl")
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_ASSUME_WEBGL=1" "SK_USE_WEBGL"
  )
endif()
#if(NOT skia_enable_skgpu_v1)
if(NOT @skia_enable_skgpu_v1@)
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_GPU_V1=0"
  )
endif()

# Some older versions of the Clang toolchain change the visibility of
# symbols decorated with API_AVAILABLE macro to be visible. Users of such
# toolchains suppress the use of this macro till toolchain updates are made.
#if(is_mac OR is_ios)
if(@is_mac@ OR @is_ios@)
  #if(skia_enable_api_available_macro)
  if(@skia_enable_api_available_macro@)
    set_property(TARGET Skia::skia APPEND PROPERTY
      INTERFACE_COMPILE_DEFINITIONS "SK_ENABLE_API_AVAILABLE"
    )
  else()
    #cflags_objcc += [ "-Wno-unguarded-availability" ]
  endif()
endif()

#config("skia_library")
set_property(TARGET Skia::skia APPEND PROPERTY
  INTERFACE_COMPILE_DEFINITIONS "SKIA_IMPLEMENTATION=1"
)

set_property(TARGET Skia::skia APPEND PROPERTY
  INTERFACE_LINK_LIBRARIES
    SkiaInternal_fontmgr_FontConfigInterface
    SkiaInternal_fontmgr_android
    SkiaInternal_fontmgr_custom_directory
    SkiaInternal_fontmgr_custom_embedded
    SkiaInternal_fontmgr_custom_empty
    SkiaInternal_fontmgr_fontconfig
    #SkiaInternal_fontmgr_fuchsia
    SkiaInternal_fontmgr_mac_ct
    #SkiaInternal_fontmgr_win
    SkiaInternal_fontmgr_win_gdi
    SkiaInternal_gpu
    SkiaInternal_graphite
    SkiaInternal_pdf
    #SkiaInternal_skcms
    SkiaInternal_xps
)

set_property(TARGET Skia::skia APPEND PROPERTY
  INTERFACE_LINK_LIBRARIES
    #SkiaInternal_android_utils
    #SkiaInternal_arm64
    #SkiaInternal_armv7
    #SkiaInternal_avx
    #SkiaInternal_crc32
    #SkiaInternal_fontmgr_factory
    SkiaInternal_gif
    SkiaInternal_heif
    #SkiaInternal_hsw
    SkiaInternal_jpeg_decode
    SkiaInternal_jpeg_encode
    SkiaInternal_ndk_images
    #SkiaInternal_none
    SkiaInternal_png_decode
    SkiaInternal_png_encode
    SkiaInternal_raw
    SkiaInternal_skvm_jit
    #SkiaInternal_skx
    #SkiaInternal_sse2
    #SkiaInternal_sse41
    #SkiaInternal_sse42
    #SkiaInternal_ssse3
    SkiaInternal_webp_decode
    SkiaInternal_webp_encode
    SkiaInternal_wuffs
    SkiaInternal_xml
)

set_property(TARGET Skia::skia APPEND PROPERTY
  INTERFACE_LINK_LIBRARIES
    SkiaInternal_default
)

#if(is_win)
if(@is_win@)
  skia_find_library_win("Ole32")
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      SkiaInternal_Ole32
  )

  skia_find_library_win("OleAut32")
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      SkiaInternal_OleAut32
  )

else()
  skia_find_library("dl")
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      SkiaInternal_dl
  )
endif()

#if(is_android)
if(@is_android@)
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      SkiaInternal_expat
  )
  skia_find_library("EGL")
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      SkiaInternal_EGL
  )
  skia_find_library("GLESv2")
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      SkiaInternal_GLESv2
  )
  skia_find_library("log")
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      SkiaInternal_log
  )
endif()

#if(is_linux OR target_cpu STREQUAL "wasm")
if(@is_linux@ OR "@target_cpu@" STREQUAL "wasm")
  #if(skia_use_egl)
  if(@skia_use_egl@)
    skia_find_library("GLESv2")
    set_property(TARGET Skia::skia APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES
        SkiaInternal_GLESv2
    )
  endif()
endif()

#if(is_mac)
if(@is_mac@)
  skia_find_framework("ApplicationServices")
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      SkiaInternal_ApplicationServices
  )
  skia_find_framework("OpenGL")
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      SkiaInternal_OpenGL
  )
endif()

#if(is_ios)
if(@is_ios@)
  skia_find_framework("CoreFoundation")
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      SkiaInternal_CoreFoundation
  )
  skia_find_framework("CoreGraphics")
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      SkiaInternal_CoreGraphics
  )
  skia_find_framework("CoreText")
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      SkiaInternal_CoreText
  )
  skia_find_framework("ImageIO")
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      SkiaInternal_ImageIO
  )
  skia_find_framework("MobileCoreServices")
  set_property(TARGET Skia::skia APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      SkiaInternal_MobileCoreServices
  )
endif()
# END of skia_component("skia")


#skia_static_library("pathkit")
add_library(SkiaInternal_pathkit INTERFACE)

# NOTE: pathkit needs 'config("skia_public")'
set_property(TARGET SkiaInternal_pathkit APPEND PROPERTY
  INTERFACE_LINK_LIBRARIES
    Skia::skia
)

#if(NOT is_component_build)
if(NOT @is_component_build@)
  skia_set_target_properties(SkiaInternal_pathkit)
  set_and_check(pathkit_LIB "${skia_LIB_DIR}/@pathkit_FILE_NAME@")
  skia_set_imported_location(SkiaInternal_pathkit STATIC
    "${pathkit_LIB}"
  )
endif()


# -------------------------------------
# END of BUILD.gn
# -------------------------------------


# -------------------------------------
# experimental/ffmpeg/BUILD.gn
# -------------------------------------
#if(skia_use_ffmpeg)
if(@skia_use_ffmpeg@)
  add_library(SkiaInternal_video_decoder INTERFACE)
  add_library(SkiaInternal_video_encoder INTERFACE)

  #if(NOT is_component_build )
  if(NOT @is_component_build@)
    skia_set_target_properties(SkiaInternal_video_decoder)
    set_and_check(video_decoder_LIB "${skia_LIB_DIR}/@video_decoder_FILE_NAME@")
    skia_set_imported_location(SkiaInternal_video_decoder STATIC
      "${video_decoder_LIB}"
    )

    skia_set_target_properties(SkiaInternal_video_encoder)
    set_and_check(video_encoder_LIB "${skia_LIB_DIR}/@video_encoder_FILE_NAME@")
    skia_set_imported_location(SkiaInternal_video_encoder STATIC
      "${video_encoder_LIB}"
    )

    skia_find_library("swscale")
    skia_find_library("avcodec")
    skia_find_library("avformat")
    skia_find_library("avutil")

    set_property(TARGET SkiaInternal_video_decoder APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES
        Skia::skia
    )
    set_property(TARGET SkiaInternal_video_decoder APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES
        SkiaInternal_swscale
    )
    set_property(TARGET SkiaInternal_video_decoder APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES
        SkiaInternal_avcodec
    )
    set_property(TARGET SkiaInternal_video_decoder APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES
        SkiaInternal_avformat
    )
    set_property(TARGET SkiaInternal_video_decoder APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES
        SkiaInternal_avutil
    )

    set_property(TARGET SkiaInternal_video_encoder APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES
        Skia::skia
    )
    set_property(TARGET SkiaInternal_video_encoder APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES
        SkiaInternal_swscale
    )
    set_property(TARGET SkiaInternal_video_encoder APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES
        SkiaInternal_avcodec
    )
    set_property(TARGET SkiaInternal_video_encoder APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES
        SkiaInternal_avformat
    )
    set_property(TARGET SkiaInternal_video_encoder APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES
        SkiaInternal_avutil
    )
  endif()
endif()


# -------------------------------------
# modules/skresources/BUILD.gn
# -------------------------------------
# static_library("skresources")
add_library(Skia_skresources INTERFACE)
add_library(Skia::skresources ALIAS Skia_skresources)

# config("public_config")
#include_dirs = [ "include" ]
set_property(TARGET Skia_skresources APPEND PROPERTY
  INTERFACE_INCLUDE_DIRECTORIES "${skia_MODULES_DIR}/skresources/include"
)

set_property(TARGET Skia_skresources APPEND PROPERTY
  INTERFACE_LINK_LIBRARIES
    Skia::skia
    SkiaInternal_video_decoder
)

#if(NOT is_component_build )
if(NOT @is_component_build@)
  set_and_check(skresources_LIB "${skia_LIB_DIR}/@skresources_FILE_NAME@")
  skia_set_imported_location(Skia_skresources STATIC
    "${skresources_LIB}"
  )
endif()


# -------------------------------------
# modules/sksg/BUILD.gn
# -------------------------------------
# skia_component("sksg")
add_library(Skia_sksg INTERFACE)
add_library(Skia::sksg ALIAS Skia_skresources)

#if(skia_enable_skottie)
if(@skia_enable_skottie@)
  # config("public_config")
  #include_dirs = [ "include" ]
  set_property(TARGET Skia_sksg APPEND PROPERTY
    INTERFACE_INCLUDE_DIRECTORIES "${skia_MODULES_DIR}/sksg/include"
  )

  set_and_check(sksg_LIB "${skia_LIB_DIR}/@sksg_FILE_NAME@")
  skia_set_imported_location(Skia_sksg ${lib_type}
    "${sksg_LIB}"
  )

  set_property(TARGET Skia_sksg APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      Skia::skia
  )
endif()



# -------------------------------------
# modules/skunicode/BUILD.gn
# -------------------------------------
#if(skia_use_icu)
if(@skia_use_icu@)
  # component("skunicode")
  add_library(Skia::skunicode ${lib_type} IMPORTED)

  # config("public_config") {
  #include_dirs = [ "include" ]
  set_property(TARGET Skia::skunicode APPEND PROPERTY
    INTERFACE_INCLUDE_DIRECTORIES "${skia_MODULES_DIR}/skunicode/include"
  )
  set_property(TARGET Skia::skunicode APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_UNICODE_AVAILABLE"
  )
  #if(is_component_build)
  if(@is_component_build@)
    set_property(TARGET Skia::skunicode APPEND PROPERTY
      INTERFACE_COMPILE_DEFINITIONS "SKUNICODE_DLL"
    )
  endif()

  set_and_check(skunicode_LIB "${skia_DLL_DIR}/@skunicode_FILE_NAME@")
  set_target_properties(Skia::skunicode PROPERTIES
    IMPORTED_LOCATION "${skunicode_LIB}"
  )
  #if(is_win AND is_component_build)
  if(@is_win@ AND @is_component_build@)
    set_and_check(skunicode_DLL_LIB "${skia_LIB_DIR}/@skunicode_DLL_LIB_FILE_NAME@")
    set_target_properties(Skia::skunicode PROPERTIES
      IMPORTED_IMPLIB "${skunicode_DLL_LIB}"
    )
  endif()
  set_property(TARGET Skia::skunicode APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      Skia::skia
  )

  # only available for Android at the moment
  #if(skia_use_runtime_icu AND (is_android OR is_linux))
  if(@skia_use_runtime_icu@ AND (@is_android@ OR @is_linux@))
    # deps += [ "//third_party/icu:headers" ]
  else()
    set_property(TARGET Skia::skunicode APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES
        SkiaInternal_icu
    )
  endif()
endif()


# -------------------------------------
# modules/skshaper/BUILD.gn
# -------------------------------------
#if(skia_enable_skshaper)
if(@skia_enable_skshaper@)
  # component("skshaper")
  add_library(Skia::skshaper ${lib_type} IMPORTED)

  # config("public_config")
  #include_dirs = [ "include" ]
  set_property(TARGET Skia::skshaper APPEND PROPERTY
    INTERFACE_INCLUDE_DIRECTORIES "${skia_MODULES_DIR}/skshaper/include"
  )
  #if(is_component_build)
  if(@is_component_build@)
    set_property(TARGET Skia::skshaper APPEND PROPERTY
      INTERFACE_COMPILE_DEFINITIONS "SKSHAPER_DLL"
    )
  endif()
  #if(skia_use_fonthost_mac)
  if(@skia_use_fonthost_mac@)
    set_property(TARGET Skia::skshaper APPEND PROPERTY
      INTERFACE_COMPILE_DEFINITIONS "SK_SHAPER_CORETEXT_AVAILABLE"
    )
  endif()
  #if(skia_use_icu AND skia_use_harfbuzz)
  if(@skia_use_icu@ AND @skia_use_harfbuzz@)
    set_property(TARGET Skia::skshaper APPEND PROPERTY
      INTERFACE_COMPILE_DEFINITIONS "SK_SHAPER_HARFBUZZ_AVAILABLE"
    )
  endif()

  set_and_check(skshaper_LIB "${skia_DLL_DIR}/@skshaper_FILE_NAME@")
  set_target_properties(Skia::skshaper PROPERTIES
    IMPORTED_LOCATION "${skshaper_LIB}"
  )
  #if(is_win AND is_component_build)
  if(@is_win@ AND @is_component_build@)
    set_and_check(skshaper_DLL_LIB "${skia_LIB_DIR}/@skshaper_DLL_LIB_FILE_NAME@")
    set_target_properties(Skia::skshaper PROPERTIES
      IMPORTED_IMPLIB "${skshaper_DLL_LIB}"
    )
  endif()
  set_property(TARGET Skia::skshaper APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      Skia::skia
  )

  #if(skia_use_fonthost_mac)
  if(@skia_use_fonthost_mac@)
    #if(is_mac)
    if(@is_mac@)
      skia_find_framework("ApplicationServices")
      set_property(TARGET Skia::skshaper APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES SkiaInternal_ApplicationServices
      )
    endif()
    #if(is_ios)
    if(@is_ios@)
      skia_find_framework("CoreFoundation")
      set_property(TARGET Skia::skshaper APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES SkiaInternal_CoreFoundation
      )
      skia_find_framework("CoreText")
      set_property(TARGET Skia::skshaper APPEND PROPERTY
        INTERFACE_LINK_LIBRARIES SkiaInternal_CoreText
      )
    endif()
  endif()
  #if(skia_use_icu AND skia_use_harfbuzz)
  if(@skia_use_icu@ AND @skia_use_harfbuzz@)
    set_property(TARGET Skia::skshaper APPEND PROPERTY
      INTERFACE_LINK_LIBRARIES Skia::skunicode SkiaInternal_harfbuzz
    )
  endif()
endif()


# -------------------------------------
# experimental/sktext/BUILD.gn
# -------------------------------------
#if(skia_enable_sktext AND skia_enable_skshaper AND skia_use_icu
#    AND skia_use_harfbuzz)
if(@skia_enable_sktext@ AND @skia_enable_skshaper@ AND @skia_use_icu@
    AND @skia_use_harfbuzz@)
  #component("sktext")
  add_library(Skia::sktext ${lib_type} IMPORTED)
  set_and_check(sktext_LIB "${skia_DLL_DIR}/@sktext_FILE_NAME@")
  set_target_properties(Skia::sktext PROPERTIES
    IMPORTED_LOCATION "${sktext_LIB}"
  )
  ##if(is_win AND is_component_build)
  #if(@is_win@ AND @is_component_build@)
  #  set_and_check(sktext_DLL_LIB "${skia_LIB_DIR}/@sktext_DLL_LIB_FILE_NAME@")
  #  set_target_properties(Skia::sktext PROPERTIES
  #    IMPORTED_IMPLIB "${sktext_DLL_LIB}"
  #  )
  #endif()
  set_property(TARGET Skia::sktext APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      Skia::skia
      Skia::skshaper
      Skia::skunicode
  )
endif()


# -------------------------------------
# modules/particles/BUILD.gn
# -------------------------------------
#if(skia_enable_particles)
if(@skia_enable_particles@)
  # static_library("particles")
  add_library(Skia_particles INTERFACE)
  add_library(Skia::particles ALIAS Skia_particles)

  # config("public_config")
  #include_dirs = [ "include" ]
  set_property(TARGET Skia_particles APPEND PROPERTY
    INTERFACE_INCLUDE_DIRECTORIES "${skia_MODULES_DIR}/particles/include"
  )

  set_property(TARGET Skia_particles APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      Skia::skia
      Skia_skresources
  )

  if(NOT @is_component_build@)
    set_and_check(particles_LIB "${skia_LIB_DIR}/@particles_FILE_NAME@")
    skia_set_imported_location(Skia_particles STATIC
      "${particles_LIB}"
    )
  endif()
endif()


# -------------------------------------
# modules/skottie/BUILD.gn
# -------------------------------------
#if(skia_enable_skottie)
if(@skia_enable_skottie@)
  # skia_component("skottie")
  add_library(Skia::skottie ${lib_type} IMPORTED)

  # config("public_config")
  #include_dirs = [ "include" ]
  set_property(TARGET Skia::skottie APPEND PROPERTY
    INTERFACE_INCLUDE_DIRECTORIES "${skia_MODULES_DIR}/skottie/include"
  )
  set_property(TARGET Skia::skottie APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_ENABLE_SKOTTIE"
  )

  set_and_check(skottie_LIB "${skia_LIB_DIR}/@skottie_FILE_NAME@")
  set_target_properties(Skia::skottie PROPERTIES
    IMPORTED_LOCATION "${skottie_LIB}"
  )
  set_property(TARGET Skia::skottie APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      Skia::skia
      Skia_skresources
      Skia::sksg
      Skia::skshaper
      Skia::skunicode
  )
endif()


# -------------------------------------
# modules/skparagraph/BUILD.gn
# -------------------------------------
#if(skia_enable_skparagraph AND skia_enable_skshaper AND skia_use_icu
#    AND skia_use_harfbuzz)
if(@skia_enable_skparagraph@ AND @skia_enable_skshaper@ AND @skia_use_icu@
    AND @skia_use_harfbuzz@)
  # skia_component("skparagraph")
  add_library(Skia::skparagraph ${lib_type} IMPORTED)

  # config("public_config") {
  #include_dirs = [ "include", "utils"]
  set_property(TARGET Skia::skparagraph APPEND PROPERTY
    INTERFACE_INCLUDE_DIRECTORIES "${skia_MODULES_DIR}/skparagraph/include"
  )
  set_property(TARGET Skia::skparagraph APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_ENABLE_PARAGRAPH"
  )

  set_and_check(skparagraph_LIB "${skia_DLL_DIR}/@skparagraph_FILE_NAME@")
  set_target_properties(Skia::skparagraph PROPERTIES
    IMPORTED_LOCATION "${skparagraph_LIB}"
  )
  ##if(is_win AND is_component_build)
  #if(@is_win@ AND @is_component_build@)
  #  set_and_check(skparagraph_DLL_LIB "${skia_LIB_DIR}/@skparagraph_DLL_LIB_FILE_NAME@")
  #  set_target_properties(Skia::skparagraph PROPERTIES
  #    IMPORTED_IMPLIB "${skparagraph_DLL_LIB}"
  #  )
  #endif()
  set_property(TARGET Skia::skparagraph APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      Skia::skia
      Skia::skshaper
      Skia::skunicode
  )
endif()


# -------------------------------------
# modules/svg/BUILD.gn
# -------------------------------------
#if(skia_enable_svg AND skia_use_expat)
if(@skia_enable_svg@ AND @skia_use_expat@)
  # skia_component("svg")
  add_library(Skia::svg ${lib_type} IMPORTED)

  # config("public_config")
  #include_dirs = [ "include" ]
  set_property(TARGET Skia::svg APPEND PROPERTY
    INTERFACE_INCLUDE_DIRECTORIES "${skia_MODULES_DIR}/svg/include"
  )
  set_property(TARGET Skia::svg APPEND PROPERTY
    INTERFACE_COMPILE_DEFINITIONS "SK_ENABLE_SVG"
  )

  set_and_check(svg_LIB "${skia_LIB_DIR}/@svg_FILE_NAME@")
  set_target_properties(Skia::svg PROPERTIES
    IMPORTED_LOCATION "${svg_LIB}"
  )
  set_property(TARGET Skia::svg APPEND PROPERTY
    INTERFACE_LINK_LIBRARIES
      Skia::skia
      Skia_skresources
      Skia::skshaper
  )
endif()


# -------------------------------------
# modules/skplaintexteditor/BUILD.gn
# -------------------------------------
#if(skia_use_icu AND skia_use_harfbuzz)
if(@skia_use_icu@ AND @skia_use_harfbuzz@)
  # NOTE: This is application
endif()



# -------------------------------------
# CMakePackageConfigHelpers
#

#check_required_components("Skia")
