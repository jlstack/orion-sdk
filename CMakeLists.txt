cmake_minimum_required(VERSION 3.5)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

project(orion-sdk)
set(PROJECT_VERSION "0.1.0-dev")

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release" CACHE STRING
    "Choose the type of build, options are: Debug Release
      RelWithDebInfo MinSizeRel." FORCE)
endif()

include(GNUInstallDirs)

# see : https://crascit.com/2016/04/09/using-ccache-with-cmake/
find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
  set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}")
else()
  message("ccache not found, repeated builds will be faster if this program is installed")
endif()

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wextra -Wall")

set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -Wextra -Wall") # -fprofile-arcs -ftest-coverage")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -Wextra -Wall") # -fprofile-arcs -ftest-coverage")

get_filename_component(PROJECT_MODULES_DIR ./cmake/Modules ABSOLUTE)

# include cmake files
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${PROJECT_MODULES_DIR})

include(MacroSubDirList)
include_directories(${PROJECT_SOURCE_DIR}/Communications)
include_directories(${PROJECT_SOURCE_DIR}/Utils)

###############################################################################
# Create the Orion library
###############################################################################
# Sources.
set(OrionLib_SOURCES
  ${PROJECT_SOURCE_DIR}/Communications/fielddecode.c
  ${PROJECT_SOURCE_DIR}/Communications/fieldencode.c
  ${PROJECT_SOURCE_DIR}/Communications/floatspecial.c
  ${PROJECT_SOURCE_DIR}/Communications/OrionComm.c
  ${PROJECT_SOURCE_DIR}/Communications/OrionCommLinux.c
  ${PROJECT_SOURCE_DIR}/Communications/OrionCommWindows.c
  ${PROJECT_SOURCE_DIR}/Communications/OrionPublicPacket.c
  ${PROJECT_SOURCE_DIR}/Communications/scaleddecode.c
  ${PROJECT_SOURCE_DIR}/Communications/scaledencode.c
  ${PROJECT_SOURCE_DIR}/Utils/dcm.c
  ${PROJECT_SOURCE_DIR}/Utils/earthposition.c
  ${PROJECT_SOURCE_DIR}/Utils/earthrotation.c
  ${PROJECT_SOURCE_DIR}/Utils/GeolocateTelemetry.c
  ${PROJECT_SOURCE_DIR}/Utils/linearalgebra.c
  ${PROJECT_SOURCE_DIR}/Utils/mathutilities.c
  ${PROJECT_SOURCE_DIR}/Utils/OrionPublicPacketShim.c
  ${PROJECT_SOURCE_DIR}/Utils/quaternion.c
  ${PROJECT_SOURCE_DIR}/Utils/TrilliumPacket.c
  ${PROJECT_SOURCE_DIR}/Utils/WGS84.c
)

# Headers.
set(OrionLib_HEADERS
  ${PROJECT_SOURCE_DIR}/Communications/fielddecode.h
  ${PROJECT_SOURCE_DIR}/Communications/fieldencode.h
  ${PROJECT_SOURCE_DIR}/Communications/floatspecial.h
  ${PROJECT_SOURCE_DIR}/Communications/OrionComm.h
  ${PROJECT_SOURCE_DIR}/Communications/OrionPublicPacket.h
  ${PROJECT_SOURCE_DIR}/Communications/OrionPublicProtocol.h
  ${PROJECT_SOURCE_DIR}/Communications/scaleddecode.h
  ${PROJECT_SOURCE_DIR}/Communications/scaledencode.h
  ${PROJECT_SOURCE_DIR}/Utils/Constants.h
  ${PROJECT_SOURCE_DIR}/Utils/dcm.h
  ${PROJECT_SOURCE_DIR}/Utils/earthposition.h
  ${PROJECT_SOURCE_DIR}/Utils/GeolocateTelemetry.h
  ${PROJECT_SOURCE_DIR}/Utils/linearalgebra.h
  ${PROJECT_SOURCE_DIR}/Utils/mathutilities.h
  ${PROJECT_SOURCE_DIR}/Utils/OrionPublicPacketShim.h  
  ${PROJECT_SOURCE_DIR}/Utils/quaternion.h
  ${PROJECT_SOURCE_DIR}/Utils/TrilliumPacket.h
  ${PROJECT_SOURCE_DIR}/Utils/Types.h
  ${PROJECT_SOURCE_DIR}/Utils/WGS84.h
)

# derived using https://gist.github.com/baiwfg2/39881ba703e9c74e95366ed422641609
# and https://crascit.com/2017/04/18/generated-sources-in-cmake-builds/
add_custom_command(
  OUTPUT ${PROJECT_SOURCE_DIR}/Communications/fielddecode.c
  OUTPUT ${PROJECT_SOURCE_DIR}/Communications/fieldencode.c
  OUTPUT ${PROJECT_SOURCE_DIR}/Communications/floatspecial.c
  OUTPUT ${PROJECT_SOURCE_DIR}/Communications/OrionPublicPacket.c
  OUTPUT ${PROJECT_SOURCE_DIR}/Communications/scaleddecode.c
  OUTPUT ${PROJECT_SOURCE_DIR}/Communications/scaledencode.c
  COMMAND ${PROJECT_SOURCE_DIR}/GenerateOrionPublicPacket.sh
  COMMENT "Generating source files using ProtoGen"
)

set(LIBRARY_NAME ${PROJECT_NAME})
add_library (${LIBRARY_NAME} SHARED
  ${OrionLib_SOURCES}
)

###############################################################################
# Installation targets
###############################################################################
install(TARGETS ${LIBRARY_NAME}
  # IMPORTANT: Add the library to the "export-set"
  EXPORT ${PROJECT_NAME}-targets
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ
)

install(FILES ${OrionLib_HEADERS}
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ
)

#############################################################################
# Generate the cmake configuration files for the build tree
#############################################################################
include(CMakePackageConfigHelpers)

configure_package_config_file(
  ${PROJECT_SOURCE_DIR}/cmake/Modules/project-config.cmake.in
  ${PROJECT_BINARY_DIR}/${PROJECT_NAME}-config.cmake
  INSTALL_DESTINATION ${PROJECT_BINARY_DIR}
)

write_basic_package_version_file(
  ${PROJECT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY SameMajorVersion
)

# Export project export set to the build tree
export(
  EXPORT ${PROJECT_NAME}-targets
  FILE "${PROJECT_BINARY_DIR}/${PROJECT_NAME}-targets.cmake"
)

# Export the package for use from the build-tree
# (this registers the build-tree with a global CMake-registry ~/.cmake)
export(PACKAGE ${PROJECT_NAME})

#############################################################################
# Generate the cmake configuration files for the install tree
#############################################################################
set(LIB_INSTALL_DIR ${CMAKE_INSTALL_LIBDIR} CACHE PATH "Library install dir")
set(CMAKE_CONFIG_DEST "${LIB_INSTALL_DIR}/${DEB_HOST_MULTIARCH}/${PROJECT_NAME}/cmake")

configure_package_config_file(
  ${PROJECT_SOURCE_DIR}/cmake/Modules/project-config.cmake.in
  ${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${PROJECT_NAME}-config.cmake
  INSTALL_DESTINATION ${CMAKE_CONFIG_DEST}
)

write_basic_package_version_file(
  ${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${PROJECT_NAME}-config-version.cmake
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY SameMajorVersion
)

# Install cmake config files
install(FILES ${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${PROJECT_NAME}-config.cmake
  ${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${PROJECT_NAME}-config-version.cmake
  DESTINATION ${CMAKE_CONFIG_DEST}
)

# Export project export set to the install tree
install(
  EXPORT ${PROJECT_NAME}-targets
  DESTINATION ${CMAKE_CONFIG_DEST}
)

file(WRITE
  ${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${PROJECT_NAME}.conf
  ${CMAKE_INSTALL_LIBDIR}
)

###############################################################################
# Binary installation generation
###############################################################################
set(CPACK_INSTALL_CMAKE_PROJECTS "${PROJECT_BINARY_DIR};${PROJECT_NAME};ALL;/")
set(CPACK_OUTPUT_CONFIG_FILE "${PROJECT_BINARY_DIR}/CPackConfig.cmake")
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "orion-sdk")
set(CPACK_GENERATOR "DEB")
set(CPACK_PACKAGE_NAME ${PROJECT_NAME})
set(CPACK_PACKAGE_RELEASE 1)
set(CPACK_PACKAGE_CONTACT "Luke Stack")
set(CPACK_PACKAGE_VENDOR "GTRI")
set(CPACK_PACKAGING_INSTALL_PREFIX ${CMAKE_INSTALL_PREFIX})
set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CPACK_PACKAGE_RELEASE}.${CMAKE_SYSTEM_PROCESSOR}")
include(CPack)
