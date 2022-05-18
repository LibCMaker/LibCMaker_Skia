#!/bin/bash

# ****************************************************************************
#  Project:  LibCMaker_libpng
#  Purpose:  A CMake build script for libpng library
#  Author:   NikitaFeodonit, nfeodonit@yandex.com
# ****************************************************************************
#    Copyright (c) 2017-2021 NikitaFeodonit
#
#    This file is part of the LibCMaker_libpng project.
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

set -e

if [[ ${cmr_CI} == "ON" ]]; then
  set -v
fi


if [[ ${cmr_CI} == "ON" ]]; then

  if [[ ${cmr_HOST_OS} == "Linux" ]] ; then
    sudo apt-get update

    if [[ ! -x "$(command -v ninja)" ]]; then
      echo "${cmr_ECHO_PREFIX} Install Ninja"
      sudo apt-get install ninja-build
    fi

    if [[ ! -x "$(command -v python3.8)" ]]; then
      echo "${cmr_ECHO_PREFIX} Install Python 3.8"
      sudo apt-get install python3.8
    fi


    if [[ ${cmr_TARGET} == "Linux" ]] ; then
      sudo apt-get install mesa-common-dev
      sudo apt-get install libglvnd-dev
    fi

    #if [[ ${cmr_TARGET} == "Android_Linux" ]] ; then
    #fi
  fi

  if [[ ${cmr_HOST_OS} == "Windows" ]] ; then
    if [[ ! -x "$(command -v ninja)" ]]; then
      echo "${cmr_ECHO_PREFIX} Install Ninja"
      choco install ninja --no-progress
    fi

    #if [[ ${cmr_TARGET} == "Android_Windows" ]] ; then
    #fi
  fi

  if [[ ${cmr_HOST_OS} == "macOS" ]] ; then
    if [[ ! -x "$(command -v ninja)" ]]; then
      echo "${cmr_ECHO_PREFIX} Install Ninja"
      brew install ninja --quiet
    fi
  fi

fi
