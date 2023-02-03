cmake_minimum_required(VERSION 3.5)

project(kdasioconfig VERSION 0.1 LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

enable_language("RC")

find_package(QT NAMES Qt6 COMPONENTS Widgets REQUIRED)
find_package(Qt6 COMPONENTS Widgets REQUIRED)
find_package(Qt6 COMPONENTS Multimedia REQUIRED)

set(PROJECT_SOURCES
        main.cpp
        kdasioconfig.cpp
        kdasioconfig.h
        kdasioconfigbase.ui
)

set(app_icon_resource_windows "${CMAKE_CURRENT_SOURCE_DIR}/mainicon.rc")

qt_add_executable(kdasioconfig
    WIN32
    MANUAL_FINALIZATION
    ${PROJECT_SOURCES}
    koordipics.qrc
    ${app_icon_resource_windows}
)

set(QAPPLICATION_CLASS QApplication CACHE STRING "Inheritance class for SingleApplication")
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/singleapplication")

target_link_libraries(kdasioconfig PRIVATE SingleApplication::SingleApplication)

target_link_libraries(kdasioconfig PRIVATE Qt6::Widgets)
target_link_libraries(kdasioconfig PRIVATE Qt6::Multimedia)

set_target_properties(kdasioconfig PROPERTIES
    OUTPUT_NAME "KoordASIOControl_builtin"
    WIN32_EXECUTABLE TRUE
)

qt_finalize_executable(kdasioconfig)
