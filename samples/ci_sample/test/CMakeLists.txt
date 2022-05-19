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
  cmr_common_sample_test_1_part()


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
  set(font_BIN_DIR "${test_BIN_DIR}")
  set(data_BIN_DIR "${test_BIN_DIR}")
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


  cmr_common_sample_test_2_part_2()


  #-----------------------------------------------------------------------
  # Run tests for Android
  #-----------------------------------------------------------------------

  if(ANDROID)
    find_program(adb_exec adb)
    if(NOT adb_exec)
      message(FATAL_ERROR "Could not find 'adb'")
    endif()

    set(TEST_WORK_DIR "/data/local/tmp/test_test")

    add_test(NAME rm_work_dir
      COMMAND ${adb_exec} shell "if [ -d \"${TEST_WORK_DIR}\" ] ; then rm -r \"${TEST_WORK_DIR}\" ; fi"
    )

    #add_test(NAME push_fonts
    #  COMMAND ${adb_exec} push "${font_BIN_DIR}" "${TEST_WORK_DIR}/fonts"
    #)
    #add_test(NAME push_data
    #  COMMAND ${adb_exec} push "${data_BIN_DIR}" "${TEST_WORK_DIR}/data"
    #)
    add_test(NAME push_bin_dir_with_test_data
      COMMAND ${adb_exec} push "${test_BIN_DIR}" "${TEST_WORK_DIR}"
    )

    if(BUILD_SHARED_LIBS)
      add_test(NAME check_tar
        COMMAND ${adb_exec} shell tar --help
      )
      set_tests_properties(check_tar PROPERTIES
        PASS_REGULAR_EXPRESSION "usage: tar"
      )
      set_tests_properties(check_tar PROPERTIES
        FAIL_REGULAR_EXPRESSION "tar: not found"
      )

      # Fix for the adb error on the arm devices if use the adb push
      # for the directory with the soft symlinks:
      # adb: error: failed to copy '<soft symlink>' to '/data/local/tmp/<soft symlink>': remote symlink failed: Permission denied
      # Instead of the direct using of the adb push use tar.
      execute_process(
        COMMAND ${CMAKE_COMMAND} -E tar cf
          "${CMAKE_CURRENT_BINARY_DIR}/lib.tar"
          "${cmr_INSTALL_DIR}/lib"
        WORKING_DIRECTORY "${cmr_INSTALL_DIR}"
      )
      add_test(NAME push_libs_tar
        COMMAND ${adb_exec} push
          "${CMAKE_CURRENT_BINARY_DIR}/lib.tar"
          "${TEST_WORK_DIR}/lib.tar"
      )
      add_test(NAME extract_libs_tar
        COMMAND ${adb_exec} shell tar --no-same-owner
          -xf "${TEST_WORK_DIR}/lib.tar"
          -C "${TEST_WORK_DIR}"
      )

      find_library(cpp_shared_LIB "c++_shared")
      if(NOT cpp_shared_LIB)
        message(FATAL_ERROR "The library 'c++_shared' can not be found.")
      endif()

      get_filename_component(cpp_shared_LIB_FILE_NAME ${cpp_shared_LIB} NAME)

      add_test(NAME push_cpp_shared
        COMMAND ${adb_exec} push
          "${cpp_shared_LIB}"
          "${TEST_WORK_DIR}/lib/${cpp_shared_LIB_FILE_NAME}"
      )
    endif()

    #add_test(NAME push_${test_NAME}
    #  COMMAND ${adb_exec} push ${test_NAME} "${TEST_WORK_DIR}/${test_NAME}"
    #)
    add_test(NAME chmod_${test_NAME}
      COMMAND ${adb_exec} shell chmod 775 "${TEST_WORK_DIR}/${test_NAME}"
    )
    add_test(NAME ${test_NAME} COMMAND ${adb_exec} shell
      "cd ${TEST_WORK_DIR} && "
      "LD_LIBRARY_PATH=${TEST_WORK_DIR}/lib ${TEST_WORK_DIR}/${test_NAME}"
      # :${LD_LIBRARY_PATH} || :/vendor/lib64:/system/lib64
    )

    add_test(NAME pull_test_result_11
      COMMAND ${adb_exec} pull
        "${TEST_WORK_DIR}/Skia_draw.ppm"
        "${CMAKE_CURRENT_BINARY_DIR}/Skia_draw.ppm"
    )
  endif()


  cmr_common_sample_test_2_part_4()
  cmr_common_sample_test_2_part_5()
endif()
