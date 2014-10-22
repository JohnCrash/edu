#include <jni.h>
#include <string>
#include "JniHelper.h"
#include "cocos2d.h"

using namespace cocos2d;

#define  CLASS_NAME "org/cocos2dx/cpp/AppActivity"

std::string g_Launch;
std::string g_Cookie;
std::string g_Userid;
std::string g_ExternalStorageDirectory;

extern "C" {
    JNIEXPORT void JNICALL Java_org_cocos2dx_cpp_AppActivity_launchParam(JNIEnv* env,jobject thiz,jstring launch,jstring cookie,jstring uid) 
	{
		g_Launch = cocos2d::JniHelper::jstring2string(launch);
		g_Cookie = cocos2d::JniHelper::jstring2string(cookie);
		g_Userid = cocos2d::JniHelper::jstring2string(uid);
    }
    JNIEXPORT void JNICALL Java_org_cocos2dx_cpp_AppActivity_setExternalStorageDirectory(JNIEnv* env,jobject thiz,jstring dir) 
	{
		g_ExternalStorageDirectory = cocos2d::JniHelper::jstring2string(dir);
    }	

	std::string takeResourceFromAndroid( int mode )
	{
		std::string ret("");
		JniMethodInfo t;
		if (JniHelper::getStaticMethodInfo(t, CLASS_NAME, "takeResource", "(I)Ljava/lang/String;")) 
		{
			jstring str = (jstring)t.env->CallStaticObjectMethod(t.classID,t.methodID,mode);
			t.env->DeleteLocalRef(t.classID);
			ret = JniHelper::jstring2string(str);
			t.env->DeleteLocalRef(str);
		}
		return ret;
	}
}

