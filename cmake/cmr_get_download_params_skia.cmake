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

# Part of "LibCMaker/cmake/cmr_get_download_params.cmake".

  include(cmr_printers)

  macro(skia_cmr_option _option _value)
    if(${_value})
      set(_opt_value "true")
    else()
      set(_opt_value "false")
    endif()
    set(${_option} "${_opt_value}" CACHE STRING "${_option}")
    unset(_opt_value)
  endmacro()


  #-----------------------------------------------------------------------
  # LibCMaker options
  #
  skia_cmr_option(export_icu_from_skia true)


  if(version VERSION_EQUAL "98")
    set(arch_file_sha "NOT_USED")
    # Commit date is Fri Jan 07 23:44:16 2022.
    set(skia_DEPOT_TOOLS_COMMIT "d3cc7ad85ed680907978c3d125b51db0f6ca5ea8")
  endif()

  set(base_url "https://skia.googlesource.com/skia.git")
  set(src_dir_name    "skia-m${version}")
  set(unpack_to_dir   "${unpacked_dir}/${src_dir_name}")
  set(unpacked_sources_dir "${unpack_to_dir}/skia")

  set(${out_ARCH_SRC_URL}   "${base_url}" PARENT_SCOPE)
  set(${out_ARCH_DST_FILE}  "${unpacked_sources_dir}/LICENSE" PARENT_SCOPE)
  set(${out_ARCH_FILE_SHA}  "${arch_file_sha}" PARENT_SCOPE)
  set(${out_SHA_ALG}        "NOT_USED" PARENT_SCOPE)
  set(${out_UNPACK_TO_DIR}  "${unpack_to_dir}" PARENT_SCOPE)
  set(${out_UNPACKED_SOURCES_DIR} "${unpacked_sources_dir}" PARENT_SCOPE)
  set(${out_VERSION_BUILD_DIR} "${build_dir}/${src_dir_name}" PARENT_SCOPE)


  set(skia_DEPOT_TOOLS_URL "https://chromium.googlesource.com/chromium/tools/depot_tools.git")
  set(skia_DEPOT_TOOLS_DIR "${unpack_to_dir}/depot_tools")
  set(skia_SRC_URL "${base_url}")
  set(skia_SRC_BRANCH "chrome/m${version}")
  set(skia_SRC_DIR "${unpacked_sources_dir}")
  set(skia_MAIN_BUILD_DIR "${unpack_to_dir}")
  set(skia_FIND_MODULE_DIR "${lib_BASE_DIR}/patch/skia-m${version}")


  find_package(Git 2.17.1 REQUIRED)
  find_package(Python REQUIRED COMPONENTS Interpreter)

  if(Python_VERSION VERSION_LESS 2.7
      OR Python_VERSION VERSION_GREATER 3.0 AND Python_VERSION VERSION_LESS 3.8)
    cmr_print_error("depot_tools requires python 2.7 or 3.8.")
  endif()


  if(NOT EXISTS ${skia_DEPOT_TOOLS_DIR})
    cmr_print_status(
      "Download depot_tools sources from\n  '${skia_DEPOT_TOOLS_URL}'\nto\n  '${skia_DEPOT_TOOLS_DIR}'"
    )
    execute_process(
      COMMAND ${CMAKE_COMMAND} -E make_directory ${skia_DEPOT_TOOLS_DIR}
    )
    execute_process(
      COMMAND ${GIT_EXECUTABLE} init --quiet
      WORKING_DIRECTORY ${skia_DEPOT_TOOLS_DIR}
    )
    execute_process(
      COMMAND ${GIT_EXECUTABLE} remote add origin ${skia_DEPOT_TOOLS_URL}
      WORKING_DIRECTORY ${skia_DEPOT_TOOLS_DIR}
    )
    execute_process(
      COMMAND ${GIT_EXECUTABLE} fetch --depth 1 origin ${skia_DEPOT_TOOLS_COMMIT}
      WORKING_DIRECTORY ${skia_DEPOT_TOOLS_DIR}
    )
    execute_process(
      COMMAND ${GIT_EXECUTABLE} checkout --quiet FETCH_HEAD
      WORKING_DIRECTORY ${skia_DEPOT_TOOLS_DIR}
    )
  endif()


  if(NOT EXISTS ${skia_SRC_DIR})
    cmr_print_status(
      "Download Skia sources from\n  '${skia_SRC_URL}'\nto\n  '${skia_SRC_DIR}'"
    )
    execute_process(
      COMMAND ${CMAKE_COMMAND} -E make_directory ${skia_SRC_DIR}
    )
    execute_process(
      COMMAND ${GIT_EXECUTABLE} init --quiet
      WORKING_DIRECTORY ${skia_SRC_DIR}
    )
    execute_process(
      COMMAND ${GIT_EXECUTABLE} remote add origin ${skia_SRC_URL}
      WORKING_DIRECTORY ${skia_SRC_DIR}
    )
    execute_process(
      COMMAND ${GIT_EXECUTABLE} fetch --depth 1 origin ${skia_SRC_BRANCH}
      WORKING_DIRECTORY ${skia_SRC_DIR}
    )
    execute_process(
      COMMAND ${GIT_EXECUTABLE} checkout --quiet FETCH_HEAD
      WORKING_DIRECTORY ${skia_SRC_DIR}
    )
  endif()


  function(apply_skia_source_patch _name)
    set(${_name}_STAMP
      "${skia_MAIN_BUILD_DIR}/patch__${_name}__.stamp"
    )
    if(NOT EXISTS ${${_name}_STAMP})
      cmr_print_status("Apply Skia source patch: '${_name}'")
      set(${_name}_FILE
        "${skia_FIND_MODULE_DIR}/${_name}"
      )
      execute_process(
        COMMAND ${GIT_EXECUTABLE} apply ${${_name}_FILE}
        #COMMAND ${GIT_EXECUTABLE} apply --reverse ${${_name}_FILE}
        WORKING_DIRECTORY ${skia_SRC_DIR}
      )
      execute_process(
        COMMAND ${CMAKE_COMMAND} -E touch ${${_name}_STAMP}
      )
    endif()
  endfunction()

  apply_skia_source_patch("GN__Android_iOS__Do_not_build__skia_c_api_example.patch")
  apply_skia_source_patch("GN__Windows__Fix_MSVC_x86_build.patch")
  apply_skia_source_patch("GN__Windows__Fix_link_deps.patch")
  apply_skia_source_patch("GN__iOS__Fix_link_deps.patch")
  apply_skia_source_patch("Src__Fix_for__skia_enable_sksl.patch")
  apply_skia_source_patch("Src__Fix_for__skia_use_sfntly.patch")
  apply_skia_source_patch("Src__Windows__Fix_MSVC_shared_build.patch")
  apply_skia_source_patch("Tools__Add_depth-1_to_git-clone_for_deps.patch")

  if(export_icu_from_skia)
    apply_skia_source_patch("GN__export_icu_from_skia.patch")
  endif()

  set(git_sync_deps_STAMP
    "${skia_MAIN_BUILD_DIR}/tools__git-sync-deps.stamp"
  )
  if(NOT EXISTS ${git_sync_deps_STAMP})
    cmr_print_status("Run 'tools/git-sync-deps'")
    execute_process(
      COMMAND ${CMAKE_COMMAND} -E env ${skia_ENV}
        ${Python_EXECUTABLE} tools/git-sync-deps
      WORKING_DIRECTORY ${skia_SRC_DIR}
    )
    execute_process(
      COMMAND ${CMAKE_COMMAND} -E touch ${git_sync_deps_STAMP}
    )
  endif()
