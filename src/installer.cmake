# include(check_git_submodule.cmake)
# check_git_submodule(dechamps_CMakeUtils)

# list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/dechamps_CMakeUtils")
find_package(InnoSetup MODULE REQUIRED)

find_package(Git MODULE REQUIRED)
# set(DECHAMPS_CMAKEUTILS_GIT_DIR "${CMAKE_CURRENT_LIST_DIR}/flexasio")
# include(version/version)
# string(REGEX REPLACE "^flexasio-" "" FLEXASIO_VERSION "${DECHAMPS_CMAKEUTILS_GIT_DESCRIPTION_DIRTY}")
string(FLEXASIO_VERSION "0.0.3" )
string(TIMESTAMP FLEXASIO_BUILD_TIMESTAMP "%Y-%m-%dT%H%M%SZ" UTC)
string(RANDOM FLEXASIO_BUILD_ID)
if (NOT DEFINED FLEXASIO_BUILD_ROOT_DIR)
    set(FLEXASIO_BUILD_ROOT_DIR "${CMAKE_CURRENT_LIST_DIR}/out/installer/${FLEXASIO_BUILD_TIMESTAMP}-${FLEXASIO_BUILD_ID}")
endif()
message(STATUS "FlexASIO build root directory: ${FLEXASIO_BUILD_ROOT_DIR}")

file(MAKE_DIRECTORY "${FLEXASIO_BUILD_ROOT_DIR}/x64" "${FLEXASIO_BUILD_ROOT_DIR}/x86")

#include(build_msvc)
#build_msvc(SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}" BUILD_DIR "${FLEXASIO_BUILD_ROOT_DIR}/x64" ARCH amd64)
#build_msvc(SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}" BUILD_DIR "${FLEXASIO_BUILD_ROOT_DIR}/x86" ARCH x86)
#@mkdir build || goto :error
#@cd build || goto :error
#call "%DECHAMPS_CMAKEUTILS_VISUALSTUDIO_VSDEVCMD%" -arch=%DECHAMPS_CMAKEUTILS_ARCH% || goto :error
#@echo on
#"%DECHAMPS_CMAKEUTILS_VISUALSTUDIO_CMAKE%" -G Ninja -DCMAKE_BUILD_TYPE="RelWithDebInfo" -DCMAKE_INSTALL_PREFIX:PATH="%DECHAMPS_CMAKEUTILS_INSTALL_DIR%" "%DECHAMPS_CMAKEUTILS_SOURCE_DIR%" || goto :error
#"%DECHAMPS_CMAKEUTILS_VISUALSTUDIO_CMAKE%" --build . --target install || goto :error


file(GLOB FLEXASIO_DOC_FILES LIST_DIRECTORIES FALSE "${CMAKE_CURRENT_LIST_DIR}/../*.txt" "${CMAKE_CURRENT_LIST_DIR}/../*.md")
file(INSTALL ${FLEXASIO_DOC_FILES} DESTINATION "${FLEXASIO_BUILD_ROOT_DIR}")

configure_file("${CMAKE_CURRENT_LIST_DIR}/installer.in.iss" "${FLEXASIO_BUILD_ROOT_DIR}/installer.iss" @ONLY)
include(execute_process_or_die)
execute_process_or_die(
    COMMAND "${InnoSetup_iscc_EXECUTABLE}" "${FLEXASIO_BUILD_ROOT_DIR}/installer.iss" /O. /FFlexASIO-${FLEXASIO_VERSION}
    WORKING_DIRECTORY "${FLEXASIO_BUILD_ROOT_DIR}"
)
