cmake_minimum_required(VERSION 3.10)

project("ultralytics")

set(OpenCV_DIR ${CMAKE_SOURCE_DIR}/OpenCV-android-sdk/sdk/native/jni)
find_package(OpenCV REQUIRED core imgproc)

#set(ncnn_DIR ${CMAKE_SOURCE_DIR}/ncnn-20230517-android-vulkan/${ANDROID_ABI}/lib/cmake/ncnn)
#find_package(ncnn REQUIRED)

add_library(${CMAKE_PROJECT_NAME} SHARED
        ultralytics.cpp
#        ncnn_camera_preview.cpp
#        ncnn_detect.cpp
#        ncnn_classify.cpp
#        ndkcamera.cpp
        tflite_detect.cpp)

find_library(
        log-lib
        log)

target_link_libraries(${CMAKE_PROJECT_NAME}
        android
#        ncnn
        ${log-lib}
        ${OpenCV_LIBS}
#        camera2ndk
#        mediandk)
        )