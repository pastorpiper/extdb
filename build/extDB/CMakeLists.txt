#Change this if you need to target a specific CMake version

cmake_minimum_required(VERSION 2.8)
cmake_policy(SET CMP0015 NEW)

set(CMAKE_USER_MAKE_RULES_OVERRIDE
   ${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules/c_flag_overrides.cmake)
set(CMAKE_USER_MAKE_RULES_OVERRIDE_CXX
   ${CMAKE_CURRENT_SOURCE_DIR}/cmake_modules/cxx_flag_overrides.cmake)
project(extDB)

set(CMAKE_SUPPRESS_REGENERATION 1)
SET(CMAKE_BUILD_TYPE "Release")
set(CMAKE_CONFIGURATION_TYPES Release CACHE TYPE  
INTERNAL FORCE )
set(CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake_modules" ${CMAKE_MODULE_PATH})

# Logging defaults to OFF
SET(DEBUG_LOGGING FALSE CACHE BOOL "Enables or disables Debug Logging.")
# Compile test application defaults to OFF
SET(COMPILE_TEST_APPLICATION FALSE CACHE BOOL "Compiles a test application of extDB.")
# Testing defaults to OFF
SET(TESTING FALSE CACHE BOOL "Sets the testing flag for extDB.")
# Test RCON defaults to OFF
SET(COMPILE_RCON_APPLICATION FALSE CACHE BOOL "Enables or disables testing of RCON.")
# Test sanitize defaults to OFF
SET(COMPILE_TEST_SANITIZE_APPLICATION FALSE CACHE BOOL "Enables or disables testing of sanitization.")


SET(SOURCES
	../../src/memory_allocator.cpp
	../../src/ext.cpp
	../../src/uniqueid.cpp
	../../src/sanitize.cpp
	../../src/protocols/abstract_protocol.cpp
	../../src/protocols/db_custom_v3.cpp
	../../src/protocols/db_custom_v5.cpp
	../../src/protocols/db_raw_v2.cpp
	../../src/protocols/db_procedure_v2.cpp
	../../src/protocols/db_raw_no_extra_quotes_v2.cpp
	../../src/protocols/misc.cpp
	../../src/protocols/log.cpp
)

if (COMPILE_TEST_APPLICATION)
	set(EXECUTABLE_NAME "extDB-test")
	add_executable(${EXECUTABLE_NAME} ${SOURCES})
	add_definitions(-DTEST_APP)
	message(STATUS "The extDB test application will be compiled.")
elseif (COMPILE_TEST_SANITIZE_APPLICATION)
	SET(SOURCES ../../src/sanitize.cpp) # Override Sources
	set(EXECUTABLE_NAME "extDB-sanitize")
	add_executable(${EXECUTABLE_NAME} ${SOURCES})
	add_definitions(-DTEST_SANITIZE_APP)
	message(STATUS "Sanitization testing is enabled.")	
elseif (COMPILE_RCON_APPLICATION)
	SET(SOURCES ../../src/rcon.cpp) # Override Sources
	set(EXECUTABLE_NAME "extDB-rcon")
	add_executable(${EXECUTABLE_NAME} ${SOURCES})
	add_definitions(-DRCON_APP)
	message(STATUS "RCON testing is enabled.")
else()
	LIST(APPEND SOURCES ../../src/main.cpp)  # Add main.cpp for library build
	set(EXECUTABLE_NAME "extDB")
	add_library (${EXECUTABLE_NAME} SHARED ${SOURCES})
endif()

if (DEBUG_LOGGING)
	add_definitions(-DDEBUG_LOGGING)
	message(STATUS "Debug Logging is enabled.")
else()
	message(STATUS "Debug Logging is disabled.")
endif()

if (TESTING)
	add_definitions(-DTESTING)
	message(STATUS "Testing flag is enabled.")
endif()


# BOOST
if(${WIN32})
	set(Boost_USE_STATIC_LIBS ON)
	set(Boost_USE_MULTITHREADED ON)
	set(Boost_USE_STATIC_RUNTIME ON)
	add_definitions(-D _WIN32_WINNT=0x0501)
else()
	add_definitions(-DBOOST_LOG_DYN_LINK)
endif()
find_package(Boost REQUIRED COMPONENTS chrono date_time filesystem log log_setup program_options random regex system thread)
if(Boost_FOUND)
	include_directories(${Boost_INCLUDE_DIRS})
	target_link_libraries(${EXECUTABLE_NAME} ${Boost_LIBRARIES})
else()
	message(FATAL_ERROR "\nBOOST not found\n Please Set BOOST_ROOT & BOOST_LIBRARYDIR")
endif()

# POCO
if(${WIN32})
	add_definitions(-D POCO_NO_UNWINDOWS)
endif()
include(FindPOCO)
if(POCO_FOUND)
	include_directories(${POCO_INCLUDE_DIR} ${POCO_Crypto_INCLUDE_DIR} ${POCO_Data_INCLUDE_DIR} ${POCO_Data_ODBC_INCLUDE_DIR})
	include_directories(${POCO_Data_SQLite_INCLUDE_DIR} ${POCO_Data_MYSQL_INCLUDE_DIR} ${POCO_Net_INCLUDE_DIR} ${POCO_Util_INCLUDE_DIR})
	target_link_libraries(${EXECUTABLE_NAME} ${POCO_LIBRARIES})
else()
	message(FATAL_ERROR "\nPOCO not found\n Please Set POCO_ROOT")
endif()

# MySQL
include(FindMySQL)
if(MYSQL_FOUND)
	include_directories(${MYSQL_INCLUDE_DIR})
	target_link_libraries(${EXECUTABLE_NAME} ${MYSQL_LIBRARY})
else()
	message(FATAL_ERROR "\nMYSQL not found")
endif()

# Look for Intel Threading Building Blocks (TBB)
include(FindTBB)
if(TBB_FOUND)
	include_directories(${TBB_INCLUDE_DIRS})
	target_link_libraries(${EXECUTABLE_NAME} ${TBB_MALLOC_LIBRARY})
else()
	message(FATAL_ERROR "\nIntel TBB not found\n Please Set TBB_ROOT")
endif()


# Look for C++11 support BOOST_NO_CXX11_NULLPTR
include(FindCXX11)
if(CXX11_FOUND)
	message(STATUS "Adding C++11 support to compiler flags: " ${CXX11_FLAGS})
	#list(APPEND CMAKE_CXX_FLAGS "${CXX11_FLAGS}")
	SET (CMAKE_CXX_FLAGS "${CXX11_FLAGS}" CACHE STRING "" FORCE)
else()
	# TODO: Add check for NullPtr, i.e for VS2010
	message(STATUS "Compiler does not support C++11") 
endif()


if(${WIN32})
	# Windows
	add_definitions(-DUNICODE -D_UNICODE)
	SET_TARGET_PROPERTIES(${EXECUTABLE_NAME} PROPERTIES LINK_FLAGS " /MANIFEST:NO /ERRORREPORT:NONE")
else()
	# Linux 
	if (NOT((COMPILE_TEST_APPLICATION) OR (COMPILE_RCON_APPLICATION) OR (COMPILE_TEST_SANITIZE_APPLICATION)))
		ADD_CUSTOM_COMMAND(
			TARGET ${EXECUTABLE_NAME}
			POST_BUILD
			COMMAND ${CMAKE_COMMAND} -E rename libextDB.so extDB.so
		)
	endif()
endif()

#check for 32bit vs. 64bit system
if (CMAKE_SIZEOF_VOID_P EQUAL 8) #64bit
	message(STATUS "Warning: You are on a 64-bit system, make sure you are pulling in the appropriate 32-bit libraries.")
elseif (CMAKE_SIZEOF_VOID_P EQUAL 4) #32bit
	message(STATUS "You are on a 32-bit system.")
else()
	message(STATUS "CMake wasn't able to identify if you are on 32-bit or 64-bit...")
endif()


mark_as_advanced(CMAKE_INSTALL_PREFIX)
mark_as_advanced(CMAKE_CONFIGURATION_TYPES)