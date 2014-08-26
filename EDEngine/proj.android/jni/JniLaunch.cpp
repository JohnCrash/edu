#include <jni.h>
#include <string>
#include "JniHelper.h"

std::string g_Launch;
std::string g_Cookie;

extern "C" {
    JNIEXPORT void JNICALL Java_org_cocos2dx_cpp_AppActivity_launchParam(JNIEnv* env,jobject thiz,jstring launch,jstring cookie) 
	{
		g_Launch = cocos2d::JniHelper::jstring2string(launch);
		g_Cookie = cocos2d::JniHelper::jstring2string(cookie);
    }
}