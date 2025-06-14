cmake_minimum_required(VERSION 3.10)

project(PassBy VERSION 0.1.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include directories
include_directories(include)

# Source files
set(SOURCES
    src/cpp/PassBy.cpp
)

# Create static library
add_library(PassBy STATIC ${SOURCES})

# Set target properties
target_include_directories(PassBy PUBLIC include)

# Platform-specific configurations
if(APPLE)
    # iOS/macOS specific settings
    set_target_properties(PassBy PROPERTIES
        FRAMEWORK TRUE
        MACOSX_FRAMEWORK_IDENTIFIER com.passby.library
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
    
    # Test source files
    set(TEST_SOURCES
        tests/test_passbymanager.cpp
    )
    
    # Create test executable
    add_executable(PassByTests ${TEST_SOURCES})
    
    # Link libraries
    target_link_libraries(PassByTests 
        PassBy
        GTest::GTest 
        GTest::Main
    )
    
    # Add test to CTest
    add_test(NAME PassByUnitTests COMMAND PassByTests)
endif()