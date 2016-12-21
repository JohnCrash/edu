LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := baidvoice-prebuilt

LOCAL_SRC_FILES := $(TARGET_ARCH_ABI)/libBDVoiceRecognitionClient_MFE_V1.so
 
include $(PREBUILT_SHARED_LIBRARY)