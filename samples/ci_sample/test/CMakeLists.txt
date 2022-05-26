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

# Testing with Google Test.
if(BUILD_TESTING)

  macro(cmr_skia_prepare_test_data)
    #-----------------------------------------------------------------------
    # Test data
    #-----------------------------------------------------------------------

    set(data_SRC_DIR "${CMAKE_CURRENT_LIST_DIR}/data")
    set(font_SRC_DIR "${data_SRC_DIR}/fonts")

    # Files in graphics_* differ in some bits.
    set(platform_graphics_SRC_DIR "${data_SRC_DIR}/graphics_1")
    if("${CMAKE_SYSTEM_NAME}" MATCHES "Linux" AND
        CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
      set(platform_graphics_SRC_DIR "${data_SRC_DIR}/graphics_2")
    endif()
    if(MSVC)
      set(platform_graphics_SRC_DIR "${data_SRC_DIR}/graphics_2")
    endif()
    if(ANDROID)
      if(NOT skia_use_fixed_gamma_text)
        if(ANDROID_ABI STREQUAL "armeabi-v7a")
          set(platform_graphics_SRC_DIR "${data_SRC_DIR}/graphics_3")
        endif()
        if(ANDROID_ABI STREQUAL "arm64-v8a")
          set(platform_graphics_SRC_DIR "${data_SRC_DIR}/graphics_2")
        endif()
        if(ANDROID_ABI STREQUAL "x86" OR ANDROID_ABI STREQUAL "x86_64")
          set(platform_graphics_SRC_DIR "${data_SRC_DIR}/graphics_1")
        endif()
      endif()
    endif()

    if(IOS)
      set(test_BIN_DIR
        "${PROJECT_BINARY_DIR}/test/$<CONFIG>-iphonesimulator/${test_NAME}.app"
      )
    else()
      set(test_BIN_DIR "${CMAKE_CURRENT_BINARY_DIR}")
    endif()
    set(font_BIN_DIR "${test_BIN_DIR}/fonts")
    set(data_BIN_DIR "${test_BIN_DIR}/data")
    if((MSVC OR XCODE) AND NOT IOS)
      set(test_BIN_DIR "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>")
    endif()


    if(TARGET Skia::icudata)
      get_target_property(icudata_LIB Skia::icudata IMPORTED_LOCATION)

      add_custom_target(prepare_icudtl_dat
        COMMAND
          ${CMAKE_COMMAND} -E make_directory "${test_BIN_DIR}"

        # `icudtl.dat` file
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
          "${icudata_LIB}"
          "${test_BIN_DIR}"
      )

      add_dependencies(${test_NAME}
        prepare_icudtl_dat
      )
    endif()

    add_custom_target(prepare_test_fonts
      COMMAND
        ${CMAKE_COMMAND} -E make_directory "${font_BIN_DIR}"

      # Arimo font
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${font_SRC_DIR}/Arimo/Arimo-BoldItalic.ttf"
        "${font_BIN_DIR}"
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${font_SRC_DIR}/Arimo/Arimo-Bold.ttf"
        "${font_BIN_DIR}"
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${font_SRC_DIR}/Arimo/Arimo-Italic.ttf"
        "${font_BIN_DIR}"
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${font_SRC_DIR}/Arimo/Arimo-Regular.ttf"
        "${font_BIN_DIR}"

      # Tinos font
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${font_SRC_DIR}/Tinos/Tinos-BoldItalic.ttf"
        "${font_BIN_DIR}"
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${font_SRC_DIR}/Tinos/Tinos-Bold.ttf"
        "${font_BIN_DIR}"
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${font_SRC_DIR}/Tinos/Tinos-Italic.ttf"
        "${font_BIN_DIR}"
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${font_SRC_DIR}/Tinos/Tinos-Regular.ttf"
        "${font_BIN_DIR}"

      # Asian fonts
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${font_SRC_DIR}/amiri-0.104/amiri-regular.ttf"
        "${font_BIN_DIR}"
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${font_SRC_DIR}/fireflysung-1.3.0/fireflysung.ttf"
        "${font_BIN_DIR}"
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${font_SRC_DIR}/AsianFonts/Sanskrit2003.ttf"
        "${font_BIN_DIR}"
    )

    add_custom_target(prepare_test_data
      COMMAND
        ${CMAKE_COMMAND} -E make_directory "${data_BIN_DIR}"

      # Graphic data
      COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${platform_graphics_SRC_DIR}/Skia_draw_test_sample.ppm"
        "${data_BIN_DIR}"
    )

    add_dependencies(${test_NAME}
      prepare_test_fonts
      prepare_test_data
    )
  endmacro()


  macro(cmr_skia_push_test_data)
    if(ANDROID)
      add_test(NAME push_fonts
        COMMAND ${adb_exec} push "${font_BIN_DIR}" "${TEST_WORK_DIR}/fonts"
      )
      add_test(NAME push_data
        COMMAND ${adb_exec} push "${data_BIN_DIR}" "${TEST_WORK_DIR}/data"
      )
    endif()
  endmacro()


  macro(cmr_skia_pull_test_result)
    if(ANDROID)
      add_test(NAME pull_test_result
        COMMAND ${adb_exec} pull
          "${TEST_WORK_DIR}/Skia_draw.ppm"
          "${PROJECT_BINARY_DIR}/Skia_draw.ppm"
      )
    endif()
  endmacro()


  #cmr_common_test_part()
  cmr_common_test_part__set_test_name()
  cmr_common_test_part__add_executable()

  cmr_skia_prepare_test_data()

  cmr_common_test_part__android__init()
  cmr_common_test_part__android__push_shared_libs()

  cmr_skia_push_test_data()

  cmr_common_test_part__android__push_test_exe()
  cmr_common_test_part__android__run_test()

  cmr_skia_pull_test_result()

  cmr_common_test_part__ios()
  cmr_common_test_part__set_common_tests_properties()


  #-----------------------------------------------------------------------
  # Test sources
  #-----------------------------------------------------------------------

  target_sources(${test_NAME}
    PRIVATE
      ${test_src_DIR}/example_test.cpp
      ${test_src_DIR}/FileUtil.cpp
  )
  set_target_properties(${test_NAME} PROPERTIES
    CXX_STANDARD 17
    C_STANDARD 11
  )

  # Skia
  target_link_libraries(${test_NAME} PRIVATE
    Skia::skshaper Skia::skunicode Skia::skia
  )
endif()
