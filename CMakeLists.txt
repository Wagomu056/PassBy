cmake_minimum_required(VERSION 3.10)

project(PassBy VERSION 0.1.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include directories
include_directories(include)

# Source files
set(SOURCES
    src/cpp/PassBy.cpp
    src/cpp/PassByBridge.cpp
)

# Platform-specific configurations
if(APPLE)
    # Add iOS-specific sources
    list(APPEND SOURCES
        ios/PassBy/PassByBLEManager.mm
        ios/PassBy/PassByiOSPlatform.mm
        src/platform/ios/iOSPlatformFactory.cpp
    )
    
    # iOS specific settings
    set(CMAKE_OSX_DEPLOYMENT_TARGET "11.0")
    set(CMAKE_OSX_ARCHITECTURES "arm64")
    if(NOT CMAKE_OSX_SYSROOT)
        set(CMAKE_OSX_SYSROOT "iphoneos")
    endif()
elseif(ANDROID)
    # Add Android-specific sources (placeholder)
    # list(APPEND SOURCES android/...)
    # list(APPEND SOURCES src/platform/android/AndroidPlatformFactory.cpp)
else()
    # For testing/development (macOS, Linux, etc.)
    list(APPEND SOURCES tests/MockPlatformFactory.cpp)
endif()

# Create library (dynamic on Apple platforms, static elsewhere)
if(APPLE)
    add_library(PassBy SHARED ${SOURCES})
else()
    add_library(PassBy STATIC ${SOURCES})
endif()

# Set target properties
target_include_directories(PassBy PUBLIC include)

# Platform-specific settings
if(APPLE)
    # Include iOS headers
    target_include_directories(PassBy PRIVATE ios)
    
    # Link Core Bluetooth framework
    find_library(CORE_BLUETOOTH CoreBluetooth)
    find_library(FOUNDATION Foundation)
    target_link_libraries(PassBy ${CORE_BLUETOOTH} ${FOUNDATION})
    
    # iOS/macOS specific settings for dynamic framework
    set_target_properties(PassBy PROPERTIES
        FRAMEWORK TRUE
        FRAMEWORK_VERSION A
        MACOSX_FRAMEWORK_IDENTIFIER com.passby.library
        VERSION 0.1.0
        SOVERSION 0.1
        MACOSX_FRAMEWORK_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/ios/PassBy/Info.plist"
    )
    
    # Copy public headers to correct framework location
    add_custom_command(TARGET PassBy POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory
        "$<TARGET_FILE_DIR:PassBy>/Headers"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_CURRENT_SOURCE_DIR}/include/PassBy/PassBy.h"
        "${CMAKE_CURRENT_SOURCE_DIR}/include/PassBy/PassByTypes.h"
        "$<TARGET_FILE_DIR:PassBy>/Headers/"
    )
elseif(ANDROID)
    # Android specific settings
    find_library(log-lib log)
    target_link_libraries(PassBy ${log-lib})
endif()

# Testing
option(BUILD_TESTING "Build the testing tree." ON)

if(BUILD_TESTING)
    enable_testing()
    
    # Find GTest
    find_package(GTest REQUIRED)
    
    # Enable testing macros for the library when building tests
    target_compile_definitions(PassBy PRIVATE PASSBY_TESTING_ENABLED)
    
    # Test source files
    set(TEST_SOURCES
        tests/test_passbymanager.cpp
    )
    
    # Create test executable
    add_executable(PassByTests ${TEST_SOURCES})
    
    # Enable testing macros for tests
    target_compile_definitions(PassByTests PRIVATE PASSBY_TESTING_ENABLED)
    
    # Link libraries
    target_link_libraries(PassByTests 
        PassBy
        GTest::GTest 
        GTest::Main
    )
    
    # Add test to CTest
    add_test(NAME PassByUnitTests COMMAND PassByTests)
    
    # Run tests serially to avoid singleton conflicts
    set_tests_properties(PassByUnitTests PROPERTIES
        RUN_SERIAL TRUE
    )
endif()