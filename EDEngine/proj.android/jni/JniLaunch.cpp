#include <jni.h>
#include <string>
#include "JniHelper.h"
#include "cocos2d.h"
#include "../../Classes/Platform.h"

using namespace cocos2d;

#define  CLASS_NAME "org/cocos2dx/cpp/AppActivity"

std::string g_Launch;
std::string g_Cookie;
std::string g_Userid;
std::string g_ExternalStorageDirectory;
std::string g_RecordFile;

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

	JNIEXPORT void JNICALL Java_org_cocos2dx_cpp_AppActivity_sendTakeResourceResult(JNIEnv* env,jobject thiz,int t,int r,jstring res)
	{
		std::string df = JniHelper::jstring2string(res);
		takeResource_callback(df,t,r);
	}

	void takeResource( int mode )
	{
		JniMethodInfo t;
		if (JniHelper::getStaticMethodInfo(t, CLASS_NAME, "takeResource", "(I)V")) 
		{
			t.env->CallStaticVoidMethod(t.classID,t.methodID,mode);
			t.env->DeleteLocalRef(t.classID);
		}
	}
	
	int startRecord( std::string file,int cnChannel,int nRate,int cnBitPerSample )
	{
		g_RecordFile = file;
		JniMethodInfo t;
		int nRet = 0;
		if (JniHelper::getStaticMethodInfo(t, CLASS_NAME, "VoiceStartRecord", "(III)I")) 
		{
			initAMREncoder(cnChannel,nRate,cnBitPerSample);
			nRet=t.env->CallStaticIntMethod(t.classID,t.methodID,cnChannel,nRate,cnBitPerSample);
			t.env->DeleteLocalRef(t.classID);
		}
		return nRet;
	}
	
	void stopRecord()
	{
		JniMethodInfo jmi;
		int nRet=0;
		if (JniHelper::getStaticMethodInfo(jmi,CLASS_NAME,"VoiceStopRecord","()I"))
		{
			nRet=jmi.env->CallStaticIntMethod(jmi.classID,jmi.methodID);
			jmi.env->DeleteLocalRef(jmi.classID);
		}
		return nRet;
	}
	
	JNIEXPORT void JNICALL Java_org_cocos2dx_cpp_AppActivity_sendVoiceRecordData(JNIEnv* env,jobject thiz,int len,int rate,jobject data)
	{
	}
}

