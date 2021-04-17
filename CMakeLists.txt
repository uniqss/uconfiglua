cmake_minimum_required(VERSION 3.2)

PROJECT(uconfig)

LIST(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
INCLUDE(cmake/ModuleImport.cmake)
INCLUDE(cmake/ModuleCompileOptions.cmake)
ModuleSetCompileOptions()
ModuleSetWinCompilerFlags()
SET(UCONFIG_VERSION_MAJOR "1")
SET(UCONFIG_VERSION_MINOR "0")
SET(UCONFIG_VERSION_PATCH "1")
SET(UCONFIG_VERSION "${UCONFIG_VERSION_MAJOR}.${UCONFIG_VERSION_MINOR}.${UCONFIG_VERSION_PATCH}")

MESSAGE(STATUS "VERSION: ${UCONFIG_VERSION}")

OPTION(USE_UCONFIG "use uconfig" OFF)

LibImport("uconfiglib" "src/uconfiglib")

# LIST(APPEND ExcludeFileListRegex "lua.c$" "luac.c$" "wmain.c$")
# DllImport3("lua53" "src/lua53" "" "${ExcludeFileListRegex}" "-DLUA_BUILD_AS_DLL -DLUA_CORE")

LIST(APPEND ExtraIncludeDirList "src/OpenXLSX/library/external/zippy" "src/OpenXLSX/library/external/pugixml" 
"src/OpenXLSX/library/external/nowide" "src/OpenXLSX/library/external")
DllImport3("OpenXLSX" "src/OpenXLSX/library" "${ExtraIncludeDirList}" "" "")

ExeImport("test" "uconfiglib;lua53;OpenXLSX")

#ADD_CUSTOM_COMMAND(
#TARGET uconfigtest
#PRE_BUILD
#COMMAND ${CMAKE_COMMAND} -E copy_if_different
#${CMAKE_CURRENT_SOURCE_DIR}/config/test.csv
#$<TARGET_FILE_DIR:uconfigtest>
#)

#INSTALL(DIRECTORY include/ DESTINATION include)
#INSTALL(TARGETS uconfig
#        RUNTIME DESTINATION bin
#        LIBRARY DESTINATION lib
#        ARCHIVE DESTINATION lib)

#SET(UCONFIG_LIBS "uconfig")
#MARK_AS_ADVANCED(${UCONFIG_LIBS})