APP_STL := gnustl_static
APP_PLATFORM := android-16
APP_CPPFLAGS := -frtti -DUSE_ZMQ -DCC_ENABLE_CHIPMUNK_INTEGRATION=1 -DCOCOS2D_DEBUG=1 -D__STDC_CONSTANT_MACROS -D__STDC_LIMIT_MACROS -D__STDC_FORMAT_MACROS -std=c++11 -fsigned-char

APP_CPPFLAGS += -fexceptions 
#APP_ABI := armeabi-v7a armeabi x86
APP_ABI := armeabi

#NDK_MODULE_PATH := ../../../cocos2d-x:../../../cocos2d-x/external:../../../cocos2d-x/cocos:../../../cocos2d-x/cocos/scripting/lua-bindings