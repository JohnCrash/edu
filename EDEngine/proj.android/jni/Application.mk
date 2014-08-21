APP_STL := gnustl_static
APP_CPPFLAGS := -frtti -DCC_ENABLE_CHIPMUNK_INTEGRATION=1 -DCOCOS2D_DEBUG=1 -std=c++11 -fsigned-char

APP_CPPFLAGS += -fexceptions 
#APP_ABI := armeabi-v7a armeabi x86
APP_ABI := armeabi