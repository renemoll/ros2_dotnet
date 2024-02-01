#
# Based on work by Robotec.ai
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set(ros2_distro "$ENV{ROS_DISTRO}")

#
# Gather ROS2 component libraries
#

macro(fetch_target_lib _target)
  string(REGEX REPLACE "::" "_" _target_normalized ${_target})
  set(_locations IMPORTED_LOCATION_NONE IMPORTED_LOCATION_NOCONFIG IMPORTED_LOCATION_RELEASE IMPORTED_LOCATION_RELWITHDEBINFO IMPORTED_LOCATION_DEBUG)
  foreach(_location ${_locations})
    get_target_property(${_target_normalized}_LIB_PATH ${_target} ${_location})
    if(NOT "${${_target_normalized}_LIB_PATH}" STREQUAL "${_target_normalized}_LIB_PATH-NOTFOUND")
      # message("+++++++++++ ${_target_normalized}_LIB_PATH: >> ${${_target_normalized}_LIB_PATH} with ${_location}")
      break()
    endif()
  endforeach()
endmacro()

set(STANDALONE_LIBS "")

macro(get_standalone_dependencies _library_name)
  find_package(${_library_name} REQUIRED)

  foreach(entry ${${_library_name}_LIBRARIES})
    if(WIN32)
      string(REGEX MATCH ".*libs\/python[0-9]*\.lib" _found ${entry})
    else()
      string(REGEX MATCH ".*python[0-9]*\.[0-9]*\.so" _found ${entry})
    endif()

    string(REGEX MATCH ".*(lib|dll|so)(\.[0-9])*$" valid ${entry})
    if (NOT valid STREQUAL "" AND _found STREQUAL "")
      list(APPEND STANDALONE_LIBS ${entry})
    endif()
  endforeach()

  # Get rmw_dds_common typesupports for dds implementations
  if("${_library_name}" STREQUAL "rmw_dds_common")
    ament_index_get_resources(middleware_implementations "rmw_typesupport")
    foreach(rmw_impl ${middleware_implementations})
      string(REGEX REPLACE "rmw_" "" rmw_impl ${rmw_impl})
      list(APPEND STANDALONE_LIBS ${rmw_dds_common_LIBRARIES__rosidl_typesupport_${rmw_impl}})
    endforeach()
  endif()

  # Get cyclonedds DDSC
  if("${_library_name}" STREQUAL "CycloneDDS")
    if(WIN32)
      if(NOT ros2_distro STREQUAL "humble")
        fetch_target_lib(CycloneDDS::ddsc)
        list(APPEND STANDALONE_LIBS ${CycloneDDS_ddsc_LIB_PATH})
      else()
        fetch_target_lib(CycloneDDS::ddsc)
        fetch_target_lib(CycloneDDS::idl)
        fetch_target_lib(CycloneDDS::dds_security_ac)
        fetch_target_lib(CycloneDDS::dds_security_auth)
        fetch_target_lib(CycloneDDS::dds_security_crypto)
        list(APPEND STANDALONE_LIBS
          ${CycloneDDS_ddsc_LIB_PATH}
          ${CycloneDDS_idl_LIB_PATH}
          ${CycloneDDS_dds_security_ac_LIB_PATH}
          ${CycloneDDS_dds_security_auth_LIB_PATH}
          ${CycloneDDS_dds_security_crypto_LIB_PATH})
      endif()
    elseif(UNIX)
      fetch_target_lib(CycloneDDS::ddsc)
      list(APPEND STANDALONE_LIBS ${CycloneDDS_ddsc_LIB_PATH})
    endif()
  endif()

  # Get rmw_cyclonedds_cpp for humble
  if("${_library_name}" STREQUAL "rmw_cyclonedds_cpp" AND (ros2_distro STREQUAL "humble" OR ros2_distro STREQUAL "rolling"))
    fetch_target_lib(rmw_cyclonedds_cpp::rmw_cyclonedds_cpp)
    list(APPEND STANDALONE_LIBS ${rmw_cyclonedds_cpp_rmw_cyclonedds_cpp_LIB_PATH})
  endif()
endmacro()

macro(install_standalone_dependencies)
  list(REMOVE_DUPLICATES STANDALONE_LIBS)

  if(WIN32)
    set(STANDALONE_DLL "")

    foreach(lib ${STANDALONE_LIBS})
      string(REGEX REPLACE "\/(l|L)ib\/" "/bin/" bin_path ${lib})
      string(REGEX REPLACE "\.lib$" ".dll" dll_path ${bin_path})
      list(APPEND STANDALONE_DLL ${dll_path})
    endforeach()

    install(
      FILES
        ${STANDALONE_DLL}
      DESTINATION
        bin
    )
  else()
      message("Unsupported platform")
  endif()
endmacro()

set(ros2_standalone_libs
  rcl
  rcl_action
  FastRTPS
  rmw_fastrtps_cpp
  CycloneDDS
  rmw_cyclonedds_cpp
  rmw_dds_common
)

foreach(ros2_standalone_lib ${ros2_standalone_libs})
  get_standalone_dependencies(${ros2_standalone_lib})
endforeach()
install_standalone_dependencies()

#
# Gather external libraries
#

set(THIRD_PARTY_STANDALONE_LIBS "")

macro(get_standalone_third_party_dependencies _library_name)
  find_file(${_library_name}_PATH "${_library_name}")
  if("${${_library_name}_PATH}" STREQUAL "${_library_name}_PATH-NOTFOUND")
    message(FATAL_ERROR "Can't find third party dependency: ${_library_name}")
  endif()

  list(APPEND THIRD_PARTY_STANDALONE_LIBS ${${_library_name}_PATH})
endmacro()

macro(install_standalone_third_party)
  install(
    FILES
      ${THIRD_PARTY_STANDALONE_LIBS}
    DESTINATION
      bin
)
endmacro()

if(WIN32)
  set(third_party_standalone_libs
    libssl-1_1-x64.dll
    libcrypto-1_1-x64.dll
    msvcp140.dll
    vcruntime140.dll
    vcruntime140_1.dll
    tinyxml2.dll
  )
  foreach(third_party_lib ${third_party_standalone_libs})
    get_standalone_third_party_dependencies(${third_party_lib})
  endforeach()
  install_standalone_third_party()
endif()
