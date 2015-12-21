LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := cocos2dcpp_shared

LOCAL_MODULE_FILENAME := libcocos2dcpp

LOCAL_SRC_FILES := hellocpp/main.cpp \
                   ../../Classes/AppDelegate.cpp \
                   ../../Classes/HelloWorldScene.cpp \
				   ../../Classes/lua_ext.cpp \
				   ../../Classes/lua_thread_curl.cpp \
				   ../../Classes/thread_curl.cpp \
				   ../../Classes/Console.cpp \
				   ../../Classes/lua_json.cpp \
				   ../../Classes/AssetsManager.cpp \
				   ../../Classes/lua_ljshell.cpp \
				   ../../Classes/MD5.cpp \
				   ../../Classes/Files.cpp \
				   ../../Classes/Platform.cpp \
				   ../../Classes/PlatformAndroid.cpp \
				   ../../Classes/RenderTextureEx.cpp \
				   ../../Classes/misc.cpp \
				   ../../Classes/IDF.cpp \
				   ../../Classes/ff.cpp \
				   ../../Classes/FFVideo.cpp \
				   ../../Classes/lua_ffmpeg.cpp \
				   ../../Classes/SDL.cpp \
				   ../../Classes/SDLAudio.cpp \
				   ../../Classes/SDL_androidaudio.cpp \
				   ../../Classes/SDLAUdioCVT.cpp \
				   ../../Classes/SDLAudioTypeCVT.cpp \
				   ../../Classes/SDLEvent.cpp \
				   ../../Classes/SDLOverlay.cpp \
				   ../../Classes/SDLSurface.cpp \
				   ../../Classes/SDLThread.cpp \
				   ../../Classes/SDLVideo.cpp \
				   ../../Classes/SDLWindow.cpp \
				   ../../Classes/acr.cpp \
				   ../../Classes/lua_thread.cpp \
				   ../../Classes/lzmq/lzmq.c \
				   ../../Classes/lzmq/lzutils.c \
				   ../../Classes/lzmq/poller.c \
				   ../../Classes/lzmq/zcontext.c \
				   ../../Classes/lzmq/zerror.c \
				   ../../Classes/lzmq/zmsg.c \
				   ../../Classes/lzmq/zpoller.c \
				   ../../Classes/lzmq/zsocket.c \
				   ../../Classes/lzmq/ztimer.c \
				   JniLaunch.cpp \
				   SDLAudioJNI.cpp

LOCAL_C_INCLUDES := $(LOCAL_PATH)/../../Classes \
					$(LOCAL_PATH)/../../Classes/lzmq \
					$(LOCAL_PATH)/../../../../cocos2d-x/cocos/base \
					$(LOCAL_PATH)/../../../../cocos2d-x/external/lua \
					$(LOCAL_PATH)/../../../../cocos2d-x/external/lua/lua \
					$(LOCAL_PATH)/../../../../cocos2d-x/external/lua/tolua \
					$(LOCAL_PATH)/../../../../cocos2d-x/cocos/platform/android/jni

LOCAL_WHOLE_STATIC_LIBRARIES := cocos_lua_static
LOCAL_WHOLE_STATIC_LIBRARIES += cocos2dx_static
LOCAL_WHOLE_STATIC_LIBRARIES += cocosdenshion_static
LOCAL_WHOLE_STATIC_LIBRARIES += box2d_static
LOCAL_WHOLE_STATIC_LIBRARIES += ffmpeg_static
LOCAL_WHOLE_STATIC_LIBRARIES += zeromq_static

include $(BUILD_SHARED_LIBRARY)

#
#NDK_MODULE_PATH := $(LOCAL_PATH)/../../../../cocos2d-x \
#	$(LOCAL_PATH)/../../../../cocos2d-x/external \
#	$(LOCAL_PATH)/../../../../cocos2d-x/cocos/scripting/lua-bindings
	
#$(call import-module,cocos)
#$(call import-module,audio/android)
#$(call import-module,Box2D)
#$(call import-module,scripting/lua-bindings)
#$(call import-module,ffmpeg/prebuilt/android)
#$(call import-module,zeromq/prebuilt/android)