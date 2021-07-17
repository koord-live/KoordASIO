 # FlexASIO CMake superbuild.

cmake_minimum_required(VERSION 3.11)
project(flexasio DESCRIPTION "FlexASIO Universal ASIO Driver Superbuild")
include(ExternalProject)
set(INTERNAL_INSTALL_PREFIX "${CMAKE_CURRENT_BINARY_DIR}/install")
set(CMAKE_ARGS
    "-DCMAKE_INSTALL_PREFIX=${INTERNAL_INSTALL_PREFIX}"
    "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
)

ExternalProject_Add(
    tinytoml
    SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/tinytoml"
    INSTALL_DIR "${INTERNAL_INSTALL_PREFIX}"
    CONFIGURE_COMMAND ""
    BUILD_COMMAND "" BUILD_ALWAYS
    INSTALL_COMMAND "${CMAKE_COMMAND}" -E copy_directory "${CMAKE_CURRENT_LIST_DIR}/tinytoml/include" "${INTERNAL_INSTALL_PREFIX}/include"
    EXCLUDE_FROM_ALL
)

ExternalProject_Add(
	portaudio
	SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/portaudio"
	INSTALL_DIR "${INTERNAL_INSTALL_PREFIX}"
    BUILD_ALWAYS TRUE USES_TERMINAL_BUILD TRUE
	CMAKE_ARGS ${CMAKE_ARGS}
		-DPA_ENABLE_DEBUG_OUTPUT=ON
		"-DCMAKE_PROJECT_portaudio_INCLUDE=${CMAKE_CURRENT_LIST_DIR}/portaudio.cmake"
	EXCLUDE_FROM_ALL
)

ExternalProject_Add(
    dechamps_cpputil
    SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/dechamps_cpputil"
    BUILD_ALWAYS TRUE USES_TERMINAL_BUILD TRUE
    INSTALL_DIR "${INTERNAL_INSTALL_PREFIX}"
    CMAKE_ARGS ${CMAKE_ARGS}
	EXCLUDE_FROM_ALL
)

ExternalProject_Add(
    dechamps_cpplog
    SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/dechamps_cpplog"
    BUILD_ALWAYS TRUE USES_TERMINAL_BUILD TRUE
    INSTALL_DIR "${INTERNAL_INSTALL_PREFIX}"
    CMAKE_ARGS ${CMAKE_ARGS}
	EXCLUDE_FROM_ALL
)

ExternalProject_Add(
    dechamps_ASIOUtil
    SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/dechamps_ASIOUtil"
	USES_TERMINAL_CONFIGURE TRUE
    BUILD_ALWAYS TRUE USES_TERMINAL_BUILD TRUE
    INSTALL_DIR "${INTERNAL_INSTALL_PREFIX}"
    CMAKE_ARGS ${CMAKE_ARGS}
	EXCLUDE_FROM_ALL
	DEPENDS dechamps_cpputil
)

ExternalProject_Add(
    FlexASIO
    SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/flexasio"
    BUILD_ALWAYS TRUE USES_TERMINAL_BUILD TRUE
    INSTALL_DIR "${INTERNAL_INSTALL_PREFIX}"
    CMAKE_ARGS ${CMAKE_ARGS}
    DEPENDS tinytoml portaudio dechamps_cpputil dechamps_ASIOUtil
)

install(DIRECTORY "${INTERNAL_INSTALL_PREFIX}/" DESTINATION "${CMAKE_INSTALL_PREFIX}")
# Remove PDB creation/installation
# install(SCRIPT dechamps_CMakeUtils/InstallPdbFiles.cmake)

# Work around https://developercommunity.visualstudio.com/content/problem/618088/cmake-msvc-toolset-version-is-incorrect-in-visual.html
# Note that for InstallRequiredSystemLibraries to work you might also need to work around https://developercommunity.visualstudio.com/content/problem/618084/cmake-installrequiredsystemlibraries-broken-in-lat.html
if (MSVC_VERSION EQUAL 1921 AND MSVC_TOOLSET_VERSION EQUAL 141)
	set(MSVC_TOOLSET_VERSION 142)
endif()
include(InstallRequiredSystemLibraries)
