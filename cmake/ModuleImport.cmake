
macro(SUBDIRLIST result curdir)
    FILE(GLOB children RELATIVE ${curdir} ${curdir}/*)
    SET(dirlist "")
    FOREACH(child ${children})
        IF(IS_DIRECTORY ${curdir}/${child})
            LIST(APPEND dirlist ${child})
        ENDIF()
    ENDFOREACH()
    SET(${result} ${dirlist})
endmacro()

macro(ModuleInclude ModuleName ModulePath)
    MESSAGE(STATUS "ModuleInclude ${ModuleName} ${ModulePath}")

    IF (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/CMakeLists.txt)
        IF (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/thirdparty)
            SUBDIRLIST(SUBDIRS ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/thirdparty)
            FOREACH(subdir ${SUBDIRS})
                ModuleInclude(${subdir} ${ModulePath}/thirdparty/${subdir})
            ENDFOREACH()
        ENDIF()

    ELSEIF(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/cmake/CMakeLists.txt)
        IF (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/thirdparty)
            SUBDIRLIST(SUBDIRS ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/thirdparty)
            FOREACH(subdir ${SUBDIRS})
                ModuleInclude(${subdir} ${ModulePath}/thirdparty/${subdir})
            ENDFOREACH()
        ENDIF()
    ELSE()

    ENDIF()

    IF (WIN32)
        INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/src/windows)
        INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/src/${ModuleName}/windows)
        LINK_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/lib)
    ENDIF(WIN32)

    INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath})
    INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/src)
    INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/src/${ModuleName})

    INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/include)
    INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/include/${ModuleName})

    INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/test)
    INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/test/${ModuleName})

endmacro(ModuleInclude)

macro(ModuleImport ModuleName ModulePath)
    MESSAGE(STATUS "ModuleImport ${ModuleName} ${ModulePath}")

    GET_PROPERTY(DMLIBS GLOBAL PROPERTY DMLIBS)

    LIST(FIND DMLIBS ${ModuleName} DMLIBS_FOUND)
    IF (DMLIBS_FOUND STREQUAL "-1")
        LIST(APPEND DMLIBS ${ModuleName})
        SET_PROPERTY(GLOBAL PROPERTY DMLIBS ${DMLIBS})

        MESSAGE(STATUS "LIST APPEND ${ModuleName} ${DMLIBS}" )

        IF (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/CMakeLists.txt)
            ADD_SUBDIRECTORY(${ModulePath})
        ELSEIF(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/cmake/CMakeLists.txt)
            ADD_SUBDIRECTORY(${ModulePath}/cmake)
        ELSE()
            MESSAGE(FATAL_ERROR "ModuleImport ${ModuleName} CMakeLists.txt not exist.")
        ENDIF()

        IF (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/thirdparty)
            SUBDIRLIST(SUBDIRS ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/thirdparty)
            FOREACH(subdir ${SUBDIRS})
                ModuleInclude(${subdir} ${ModulePath}/thirdparty/${subdir})
            ENDFOREACH()
        ENDIF()

        ModuleInclude(${ModuleName} ${ModulePath})
    ELSE()
        IF (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/thirdparty)
            SUBDIRLIST(SUBDIRS ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/thirdparty)
            FOREACH(subdir ${SUBDIRS})
                ModuleInclude(${subdir} ${ModulePath}/thirdparty/${subdir})
            ENDFOREACH()
        ENDIF()
        ModuleInclude(${ModuleName} ${ModulePath})
        MESSAGE(STATUS "LIST REPEAT ${ModuleName} ${DMLIBS}" )
    ENDIF()
endmacro(ModuleImport)

macro(ExeImport ModulePath DependsLib)
    MESSAGE(STATUS "ExeImport ${ModulePath} ${DependsLib}")

    IF (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath})
        SUBDIRLIST(SUBDIRS ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath})
        FOREACH(subdir ${SUBDIRS})
            MESSAGE(STATUS "INCLUDE -> ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/${subdir}")
            INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/${subdir})
            FILE(GLOB_RECURSE BIN_SOURCES
            ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/${subdir}/*.cpp
            ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/${subdir}/*.cc
            ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/${subdir}/*.c
            ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/${subdir}/*.hpp
            ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/${subdir}/*.h)

            LIST(FILTER BIN_SOURCES EXCLUDE REGEX "${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/${subdir}/tpl/*")

            MESSAGE(STATUS "BIN_SOURCES ${LIB_SOURCES}")

            ADD_EXECUTABLE(${subdir} ${BIN_SOURCES})
            TARGET_LINK_LIBRARIES(${subdir} ${DependsLib})
        ENDFOREACH()
    ENDIF()

endmacro(ExeImport)

macro(LibImport ModuleName ModulePath)
    MESSAGE(STATUS "LibImport ${ModuleName} ${ModulePath}")
    IF (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath})
        ModuleInclude(${ModuleName} ${ModulePath})
        FILE(GLOB_RECURSE LIB_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/include/*.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h

        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.c
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.h
        )

        LIST(FILTER LIB_SOURCES EXCLUDE REGEX "${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/tpl/*")

        IF (WIN32)
            LIST(APPEND LIB_SOURCES)
        ENDIF(WIN32)

        ADD_LIBRARY(${ModuleName} ${LIB_SOURCES})
    ENDIF()
endmacro(LibImport)

macro(DllImport ModuleName ModulePath ExcludeFileListRegex)
    MESSAGE(STATUS "DllImport ${ModuleName} ${ModulePath} ${ExcludeFileListRegex}")

    IF (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath})
        ModuleInclude(${ModuleName} ${ModulePath})
        FILE(GLOB_RECURSE LIB_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/include/*.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h

        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.c
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.h
        )

        LIST(FILTER LIB_SOURCES EXCLUDE REGEX "${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/tpl/*")

        FOREACH(tmpFile ${ExcludeFileListRegex})
            LIST(FILTER LIB_SOURCES EXCLUDE REGEX ${tmpFile})
        ENDFOREACH(tmpFile)

        IF (WIN32)
            LIST(APPEND LIB_SOURCES)
        ENDIF(WIN32)

        ADD_LIBRARY(${ModuleName} SHARED ${LIB_SOURCES})
    ENDIF()
endmacro(DllImport)

macro(DllImport3 ModuleName ModulePath ExtraDirList ExcludeFileListRegex CompileFlagsList)
    MESSAGE(STATUS "DllImport3 ${ModuleName} ${ModulePath} ${ExcludeFileListRegex} ${CompileFlagsList}")

    FOREACH(__dir ${ExtraDirList})
        IF (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${__dir})
            INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/${__dir})
        ENDIF()
    ENDFOREACH(__dir)

    LIST(APPEND OTHER_INCLUDES ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath} ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/include 
    ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/inc ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/headers)
    FOREACH(__include ${OTHER_INCLUDES})
        IF (IS_DIRECTORY ${__include})
            INCLUDE_DIRECTORIES(${__include})
        ENDIF()
    ENDFOREACH(__include)
    
    FILE(GLOB DLL_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/include/*.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h

        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.c
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.h

        FOREACH(__dir ${ExtraDirList})
            IF (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${__dir})
                MESSAGE(STATUS "fuck fuck fuck ${CMAKE_CURRENT_SOURCE_DIR}/${__dir}")
                ${CMAKE_CURRENT_SOURCE_DIR}/${__dir}/*.cpp
                ${CMAKE_CURRENT_SOURCE_DIR}/${__dir}/*.cc
                ${CMAKE_CURRENT_SOURCE_DIR}/${__dir}/*.c
                ${CMAKE_CURRENT_SOURCE_DIR}/${__dir}/*.hpp
                ${CMAKE_CURRENT_SOURCE_DIR}/${__dir}/*.h
            ENDIF()
        ENDFOREACH(__dir)
        
        IF (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/src)
            ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/src/*.cpp
            ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/src/*.cc
            ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/src/*.c
            ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/src/*.hpp
            ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/src/*.h
        ENDIF()

        IF (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/sources)
            ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/sources/*.cpp
            ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/sources/*.cc
            ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/sources/*.c
            ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/sources/*.hpp
            ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/sources/*.h
        ENDIF()
    )

    FOREACH(tmpFile ${ExcludeFileListRegex})
        LIST(FILTER DLL_SOURCES EXCLUDE REGEX ${tmpFile})
    ENDFOREACH(tmpFile)

    ADD_LIBRARY(${ModuleName} SHARED ${DLL_SOURCES})
    
    IF (NOT ${CompileFlagsList} STREQUAL "")
        SET_TARGET_PROPERTIES(${ModuleName} PROPERTIES COMPILE_FLAGS ${CompileFlagsList})
    ENDIF()

    IF (WIN32)
    ELSEIF (APPLE)
        SET_TARGET_PROPERTIES(${ModuleName} PROPERTIES COMPILE_FLAGS "-Wl,-undefined -Wl,dynamic_lookup")
        SET_TARGET_PROPERTIES(${ModuleName} PROPERTIES PREFIX "")
        SET_TARGET_PROPERTIES(${ModuleName} PROPERTIES SUFFIX ".so")
    ELSEIF (UNIX)
        SET_TARGET_PROPERTIES(${ModuleName} PROPERTIES COMPILE_FLAGS "-Wl,-E")
    ENDIF ()
endmacro(DllImport3)

macro(LibImportDepends ModuleName ModulePath DependsLib)
    MESSAGE(STATUS "LibImportDepends ${ModuleName} ${ModulePath} ${DependsLib}")

    IF (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath})
        ModuleInclude(${ModuleName} ${ModulePath})
        FILE(GLOB_RECURSE LIB_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/include/*.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h

        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.c
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.h
        )

        LIST(FILTER LIB_SOURCES EXCLUDE REGEX "${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/tpl/*")

        IF (WIN32)
            LIST(APPEND LIB_SOURCES)
        ENDIF(WIN32)

        ADD_LIBRARY(${ModuleName} STATIC ${LIB_SOURCES})
        TARGET_LINK_LIBRARIES(${ModuleName} ${DependsLib})
    ENDIF()
endmacro(LibImportDepends)

macro(DllImportDepends ModuleName ModulePath DependsLib)
    MESSAGE(STATUS "DllImportDepends ${ModuleName} ${ModulePath} ${DependsLib}")

    IF (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath})
        ModuleInclude(${ModuleName} ${ModulePath})
        FILE(GLOB_RECURSE LIB_SOURCES
        ${CMAKE_CURRENT_SOURCE_DIR}/include/*.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/include/*.h

        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.c
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.hpp
        ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/*.h
        )

        LIST(FILTER LIB_SOURCES EXCLUDE REGEX "${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/tpl/*")

        IF (WIN32)
            LIST(APPEND LIB_SOURCES)
        ENDIF(WIN32)

        ADD_LIBRARY(${ModuleName} SHARED ${LIB_SOURCES})
        TARGET_LINK_LIBRARIES(${ModuleName} ${DependsLib})
    ENDIF()
endmacro(DllImportDepends)

macro(ModuleInclude2 ModuleName ModulePath)
    MESSAGE(STATUS "ModuleInclude2 ${ModuleName} ${ModulePath}")

    IF (WIN32)
        INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/include/${ModuleName})
        INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/include)

        LINK_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/lib)
    ELSE(WIN32)
        IF (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/cmake/Find${ModuleName}.cmake)
            INCLUDE(${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/cmake/Find${ModuleName}.cmake)
            INCLUDE_DIRECTORIES(${${ModuleName}_INCLUDE_DIRS})
        ELSE()
            MESSAGE(FATAL_ERROR "ModuleImport2 ${ModuleName} Find${ModuleName}.cmake not exist.")
        ENDIF()
    ENDIF(WIN32)

endmacro(ModuleInclude2)

macro(ModuleImport2 ModuleName ModulePath)
    MESSAGE(STATUS "ModuleImport2 ${ModuleName} ${ModulePath}")

    IF (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/thirdparty)
        SUBDIRLIST(SUBDIRS ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath}/thirdparty)
        FOREACH(subdir ${SUBDIRS})
            ModuleInclude2(${ModuleName} ${ModulePath}/thirdparty/${subdir})
        ENDFOREACH()
    ENDIF()

    ModuleInclude2(${ModuleName} ${ModulePath})
endmacro(ModuleImport2)

macro(ModuleImportAll ModulePath)
    MESSAGE(STATUS "ModuleImportAll ${ModulePath}")

    IF (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath})
        SUBDIRLIST(SUBDIRS ${CMAKE_CURRENT_SOURCE_DIR}/${ModulePath})
        FOREACH(subdir ${SUBDIRS})
            MESSAGE(STATUS "ModuleImportAll ${subdir} ${ModulePath}/${subdir}")

            ModuleImport(${subdir} ${ModulePath}/${subdir})
        ENDFOREACH()
    ENDIF()
endmacro(ModuleImportAll)

macro(ModuleConfigure ModuleName ModulePath)
    IF (WIN32)
        ADD_CUSTOM_TARGET(
            ${ModuleName}_configure
            COMMAND echo "${ModuleName}_config"
            WORKING_DIRECTORY ${ModulePath}
            )
    ELSEIF (APPLE)
        ADD_CUSTOM_TARGET(
            ${ModuleName}_configure
            COMMAND glibtoolize && aclocal && autoheader && autoconf && automake --add-missing && sh configure
            WORKING_DIRECTORY ${ModulePath}
            )
    ELSEIF (UNIX)
        ADD_CUSTOM_TARGET(
            ${ModuleName}_configure
            COMMAND libtoolize && aclocal && autoheader && autoconf && automake --add-missing && sh configure
            WORKING_DIRECTORY ${ModulePath}
            )
    ENDIF()

    ADD_DEPENDENCIES(${ModuleName} ${ModuleName}_configure)
endmacro(ModuleConfigure)

macro(ModuleCommand ModuleName ModulePath CommandLine)
    MESSAGE(STATUS "ModuleCommand ${ModuleName} ${ModulePath} ${CommandLine}")

    IF (WIN32)
        ADD_CUSTOM_TARGET(
            ${ModuleName}_command
            COMMAND ${CommandLine}
            WORKING_DIRECTORY ${ModulePath}
            )
    ELSEIF (APPLE)
        ADD_CUSTOM_TARGET(
            ${ModuleName}_command
            COMMAND ${CommandLine}
            WORKING_DIRECTORY ${ModulePath}
            )
    ELSEIF (UNIX)
        ADD_CUSTOM_TARGET(
            ${ModuleName}_command
            COMMAND ${CommandLine}
            WORKING_DIRECTORY ${ModulePath}
            )
    ENDIF()

    ADD_DEPENDENCIES(${ModuleName} ${ModuleName}_command)
endmacro(ModuleCommand)
