cmake_minimum_required(VERSION 3.5)
project(orion-sdk)
set(PROJECT_VERSION "0.1.0-dev")

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# if(NOT CMAKE_BUILD_TYPE)
#   set(CMAKE_BUILD_TYPE "Release" CACHE STRING
#     "Choose the type of build, options are: Debug Release
#       RelWithDebInfo MinSizeRel." FORCE)
# endif()

set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -Wextra -fPIC")
set (CMAKE_CXX_FLAGS_DEBUG   "${CMAKE_CXX_FLAGS} -O0 -ggdb3 -DDEBUG")
set (CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS} -O3")

# see : https://crascit.com/2016/04/09/using-ccache-with-cmake/
find_program(CCACHE_PROGRAM ccache)
if(CCACHE_PROGRAM)
  set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE "${CCACHE_PROGRAM}")
else()
  message("ccache not found, repeated builds will be faster if this program is installed")
endif()

# fetch all the local directories for generated code
get_filename_component(PROJECT_INC_DIR ./include ABSOLUTE)
get_filename_component(PROJECT_MODULES_DIR ./cmake/Modules ABSOLUTE)

# include cmake files
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${PROJECT_MODULES_DIR})

include(MacroSubDirList)
include_directories(${PROJECT_SOURCE_DIR}/Communications)
include_directories(${PROJECT_SOURCE_DIR}/Utils)


###############################################################################
# Build the Orion libraries and import them as targets.
###############################################################################

# See: https://cmake.org/cmake/help/latest/command/add_custom_command.html
add_custom_command(
  OUTPUT ${PROJECT_SOURCE_DIR}/Communications/aarch64/libOrionComm.a
  OUTPUT ${PROJECT_SOURCE_DIR}/Utils/aarch64/libOrionUtils.a
  COMMAND cd ${PROJECT_SOURCE_DIR}/ProtoGen && qtchooser -run-tool=qmake -qt=qt5 ProtoGen.pro && make clean && make
  COMMAND cd ${PROJECT_SOURCE_DIR} && make clean && make TARGET=aarch64
  COMMENT "Generating source files using ProtoGen and building aarch64 version of orion-sdk"
  )

# Create a target out of the library compilation result.
# See: https://stackoverflow.com/questions/31274577/custom-target-as-a-target-library-in-cmake
add_custom_target(orion-libcomms-build DEPENDS
  ${PROJECT_SOURCE_DIR}/Communications/aarch64/libOrionComm.a
  )
add_custom_target(orion-libutils-build DEPENDS
  ${PROJECT_SOURCE_DIR}/Utils/aarch64/libOrionUtils.a
  )

# NOTE: Defining the aarch64 libraries ONLY!
add_library(OrionComm STATIC IMPORTED GLOBAL)
add_dependencies(OrionComm orion-libcomms-build)
set_target_properties(OrionComm PROPERTIES
  IMPORTED_LOCATION ${PROJECT_SOURCE_DIR}/Communications/aarch64/libOrionComm.a
  INTERFACE_INCLUDE_DIRECTORIES ${PROJECT_SOURCE_DIR}/Communications
  )
list(APPEND PROJECT_LIBS OrionComm)


add_library(OrionUtil STATIC IMPORTED GLOBAL)
add_dependencies(OrionUtil orion-libutils-build)
set_target_properties(OrionUtil PROPERTIES
  IMPORTED_LOCATION ${PROJECT_SOURCE_DIR}/Utils/aarch64/libOrionUtils.a
  INTERFACE_INCLUDE_DIRECTORIES ${PROJECT_SOURCE_DIR}/Utils
  )
list(APPEND PROJECT_LIBS OrionUtil)



###############################################################################
# Installation targets
###############################################################################

# We can't install imported targets
# See: https://stackoverflow.com/questions/41175354/can-i-install-shared-imported-library

# Install the libraries.
foreach(LIB_NAME ${PROJECT_LIBS})
  get_target_property(lib-location ${LIB_NAME} IMPORTED_LOCATION)
  install(FILES ${lib-location} DESTINATION ${CMAKE_INSTALL_LIBDIR})
endforeach()

# Install the header files.
install(DIRECTORY ${PROJECT_SOURCE_DIR}/Communications
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  FILES_MATCHING PATTERN "*.h"
  )
install(DIRECTORY ${PROJECT_SOURCE_DIR}/Utils
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
  FILES_MATCHING PATTERN "*.h"
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

# write_basic_package_version_file(
#   ${PROJECT_BINARY_DIR}/${PROJECT_NAME}-config-version.cmake
#   VERSION ${PROJECT_VERSION}
#   COMPATIBILITY SameMajorVersion
# )

# Export project export set to the build tree
# export(
#   EXPORT ${PROJECT_NAME}-targets
#   FILE "${PROJECT_BINARY_DIR}/${PROJECT_NAME}-targets.cmake"
# )

# Export the package for use from the build-tree
# (this registers the build-tree with a global CMake-registry ~/.cmake)
export(PACKAGE ${PROJECT_NAME})


# #############################################################################
# # Generate the cmake configuration files for the install tree
# #############################################################################
# set(LIB_INSTALL_DIR ${CMAKE_INSTALL_LIBDIR} CACHE PATH "Library install dir")
# set(CMAKE_CONFIG_DEST "${LIB_INSTALL_DIR}/${DEB_HOST_MULTIARCH}/${PROJECT_NAME}/cmake")

# configure_package_config_file(
#   ${PROJECT_SOURCE_DIR}/cmake/Modules/project-config.cmake.in
#   ${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${PROJECT_NAME}-config.cmake
#   INSTALL_DESTINATION ${CMAKE_CONFIG_DEST}
# )

# # write_basic_package_version_file(
# #   ${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${PROJECT_NAME}-config-version.cmake
# #   VERSION ${PROJECT_VERSION}
# #   COMPATIBILITY SameMajorVersion
# # )

# # # Install cmake config files
# # install(FILES ${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${PROJECT_NAME}-config.cmake
# #   ${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${PROJECT_NAME}-config-version.cmake
# #   DESTINATION ${CMAKE_CONFIG_DEST}
# # )

# # Export project export set to the install tree
# install(
#   EXPORT ${PROJECT_NAME}-targets
#   DESTINATION ${CMAKE_CONFIG_DEST}
#   )

# # file(WRITE
# #   ${PROJECT_BINARY_DIR}/${CMAKE_FILES_DIRECTORY}/${PROJECT_NAME}.conf
# #   ${CMAKE_INSTALL_LIBDIR}
# #   )

# # # Export the package for use from the build-tree
# # # (this registers the build-tree with a global CMake-registry ~/.cmake)
# # export(PACKAGE ${PROJECT_NAME})

###############################################################################
# Binary installation generation
###############################################################################
set(CPACK_INSTALL_CMAKE_PROJECTS "${CMAKE_CURRENT_BINARY_DIR};${PROJECT_NAME};ALL;/")
set(CPACK_OUTPUT_CONFIG_FILE "${PROJECT_BINARY_DIR}/CPackConfig.cmake")
set(CPACK_PACKAGE_VERSION "0.0.1")
set(CPACK_GENERATOR "DEB")
set(CPACK_PACKAGE_NAME ${PROJECT_NAME})
set(CPACK_PACKAGE_RELEASE 1)
set(CPACK_PACKAGE_CONTACT "Sergio Garcia-Vergara")
set(CPACK_PACKAGE_VENDOR "GTRI")
set(CPACK_PACKAGING_INSTALL_PREFIX ${ROS_INSTALL_PREFIX})
set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION}-${CPACK_PACKAGE_RELEASE}.${CMAKE_SYSTEM_PROCESSOR}")
include(CPack)
