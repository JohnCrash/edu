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
				   ../../Classes/AssetsManager.cpp

LOCAL_C_INCLUDES := $(LOCAL_PATH)/../../Classes \
					$(LOCAL_PATH)/../../../../cocos2d-x/cocos/base \
					$(LOCAL_PATH)/../../../../cocos2d-x/external/lua/lua \
					$(LOCAL_PATH)/../../../../cocos2d-x/external/lua/tolua \

LOCAL_WHOLE_STATIC_LIBRARIES := cocos_lua_static
LOCAL_WHOLE_STATIC_LIBRARIES += cocos2dx_static
LOCAL_WHOLE_STATIC_LIBRARIES += cocosdenshion_static
LOCAL_WHOLE_STATIC_LIBRARIES += box2d_static


include $(BUILD_SHARED_LIBRARY)

#$(call import-module,cocos)
$(call import-module,audio/android)
$(call import-module,Box2D)
$(call import-module,scripting/lua-bindings)
